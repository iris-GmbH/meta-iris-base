#!/bin/sh

TAG=$0

log() {
	logger -t "$TAG" "$1"
	echo "$TAG $1"
}

exists() {
	command -v "$1" >/dev/null 2>&1 || { log "ERROR: $1 not found"; return 1; }
}

# pidofproc()
. /etc/init.d/functions


power_on_selftest() {
	# Check that all necessary tools are available and running
	tools="nginx WebInterfaceServer swupdate count_von_count i6ls"
	log "[STARTED] power on self test started!"
	for tool in $tools; do
		exists "$tool" || return 1
		retries=5
		while [ "$retries" -gt 0 ]; do
			if pidofproc "$tool" >/dev/null 2>&1; then
				log "[PASSED] $tool"; break;
			else
				log "Retry $((i+=1)) getting pid of $tool"; sleep 1;
			fi
			retries=$((retries-1))
		done
		if [ "$retries" -eq 0 ]; then
			log "[FAILED] power on self test"; return 1;
		fi
	done
	log "[PASSED] power on self test"
	return 0
}

get_firmware_bootpath() {
	if grep -q 'linuxboot_b\|firmware_b' /proc/cmdline; then
		CUR_FITIMAGE_DEV=/dev/mmcblk2p3
		ALT_FITIMAGE_DEV=/dev/mmcblk2p2
		CUR_FW_SUFFIX="b"
		ALT_FW_SUFFIX="a"
	else
		CUR_FITIMAGE_DEV=/dev/mmcblk2p2
		ALT_FITIMAGE_DEV=/dev/mmcblk2p3
		CUR_FW_SUFFIX="a"
		ALT_FW_SUFFIX="b"
	fi
}

update_alternative_firmware() {
	err=0
	log "Start updating alternative firmware: $ALT_FW_SUFFIX"

	# Update alternative fitImage partition
	mkdir /tmp/cur_fitimage_dev /tmp/alt_fitimage_dev
	mount "$CUR_FITIMAGE_DEV" /tmp/cur_fitimage_dev
	mount "$ALT_FITIMAGE_DEV" /tmp/alt_fitimage_dev
	cp /tmp/cur_fitimage_dev/fitImage.signed /tmp/alt_fitimage_dev/fitImage.signed || \
		{ log "Error: Failed to copy alternative fitImage"; err=1; }
	umount /tmp/cur_fitimage_dev /tmp/alt_fitimage_dev
	rm -r /tmp/cur_fitimage_dev /tmp/alt_fitimage_dev
	[ "$err" -eq 0 ] || return "$err"

	# Resize the rootfs volume before copying
	# Read new volume size from current rootfs volume (trim leading spaces from lvs output), compare with size of alternative rootfs volume
	new_size=$(lvs "/dev/mapper/irma6lvm-rootfs_${CUR_FW_SUFFIX}" -o LV_SIZE --noheadings --units B --nosuffix | sed 's/^ *//g')
	alt_size=$(lvs "/dev/mapper/irma6lvm-rootfs_${ALT_FW_SUFFIX}" -o LV_SIZE --noheadings --units B --nosuffix | sed 's/^ *//g')

	# Resize alternate rootfs volume
	if [ "$new_size" != "$alt_size" ]; then
		lvresize --autobackup n --force --yes --quiet -L "$new_size"B "/dev/mapper/irma6lvm-rootfs_${ALT_FW_SUFFIX}" 2> /dev/null || \
			{ log "Error: Failed to resize alternative rootfs volume"; err=1; }
	fi
	vgmknodes

	[ "$err" -eq 0 ] || return "$err"

	# Update alternative rootfs and rootfs hashtree volumes
	dd if="/dev/mapper/irma6lvm-rootfs_${CUR_FW_SUFFIX}" of="/dev/mapper/irma6lvm-rootfs_${ALT_FW_SUFFIX}" bs=10M >/dev/null 2>&1 || \
		{ log "Error: Failed to copy alternative rootfs"; err=1; return "$err"; }
	dd if="/dev/mapper/irma6lvm-rootfs_${CUR_FW_SUFFIX}_hash" of="/dev/mapper/irma6lvm-rootfs_${ALT_FW_SUFFIX}_hash" bs=10M >/dev/null 2>&1 || \
		{ log "Error: Failed to copy alternative rootfs hash device"; err=1; return "$err"; }

	# Update alternative roothash.signature
	mount /dev/mapper/irma6lvm-keystore /mnt/keystore
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash.signature" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash.signature" || \
		{ log "Error: Failed to copy alternative roothash.signature"; err=1; }

	# Update lastly the roothash, which is used as parameter verify if the alt rootfs needs to be updated
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash" || \
		{ log "Error: Failed to copy alternative roothash"; err=1; }
	umount /mnt/keystore

	# Delete obsolete directories that were migrated in pre_post_install script
	# can be removed on major release 5
	rm -rf "/mnt/iris/counter/webserver"
	sync

	return "$err";
}

update_alternative_userdata(){
	log "Synchronizing config from ${CUR_FW_SUFFIX} to ${ALT_FW_SUFFIX}"

	# Update alternative userdata
	# can be removed on major release 5
	if lvdisplay /dev/irma6lvm/userdata > /dev/null 2>&1; then
		# rename old partition to A/B format
		lvrename -y -A n /dev/irma6lvm/userdata userdata_${ALT_FW_SUFFIX}
	fi

	err=0
	dmsetup create decrypted-irma6lvm-userdata_${ALT_FW_SUFFIX} --table \
		"0 $(blockdev --getsz /dev/mapper/irma6lvm-userdata_${ALT_FW_SUFFIX}) \
		crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-userdata_${ALT_FW_SUFFIX} 0 1 sector_size:4096"

	# resize alternative userdata to 256mb
	# can be removed on major release 5
	cur_size=$(lvs --select "lv_name = userdata_${ALT_FW_SUFFIX}" -o LV_SIZE --units m --nosuffix --noheadings | sed 's/  \([0-9]*\).*/\1/')
	req_size=256 # mb
	if [ "$cur_size" -gt "$req_size" ]; then
		log "Resize userdata_${ALT_FW_SUFFIX} to $req_size M"
		e2fsck -f -p /dev/mapper/decrypted-irma6lvm-userdata_${ALT_FW_SUFFIX} || err=1
		resize2fs "/dev/mapper/decrypted-irma6lvm-userdata_${ALT_FW_SUFFIX}" "$req_size"M || err=1
		lvresize --autobackup n --force --yes --quiet -L "$req_size"M "/dev/mapper/irma6lvm-userdata_${ALT_FW_SUFFIX}" || err=1
	fi

	# sync userdata A and B
	USERDATA_MOUNTP="/tmp/userdata_${ALT_FW_SUFFIX}"
	mkdir -p $USERDATA_MOUNTP
	mount -t ext4 /dev/mapper/decrypted-irma6lvm-userdata_${ALT_FW_SUFFIX} $USERDATA_MOUNTP || err=1
	rsync -a --delete /mnt/iris/ $USERDATA_MOUNTP || err=1
	sync
	umount $USERDATA_MOUNTP
	rm -rf $USERDATA_MOUNTP
	dmsetup remove decrypted-irma6lvm-userdata_${ALT_FW_SUFFIX}

	return "$err"
}

# return values
# 0: update required
# 1: update not required
is_alt_fw_update_required() {
	ret=1

	# Alternative firmware needs an update if roothash differs
	mount /dev/mapper/irma6lvm-keystore /mnt/keystore
	if ! cmp -s /mnt/keystore/rootfs_a_roothash /mnt/keystore/rootfs_b_roothash; then
		ret=0
	fi
	umount /mnt/keystore
	return "$ret"
}

reset_uboot_envs() {
	TMP_ENV_FILE="/tmp/reset_update_envs"

	# Always set firmware to the current one
	# Default to firmware=0 if value is invalid
	grep -q 'linuxboot_b\|firmware_b' /proc/cmdline && firmware=1 || firmware=0
	printf "bootcount=0\nupgrade_available=\nustate=\nfirmware=%s\n" "$firmware" > "$TMP_ENV_FILE"

	# Use a temp file to write u-boot-env's in one go
	fw_setenv -s "$TMP_ENV_FILE"
	rm "$TMP_ENV_FILE"
}

update_security_report(){
	MONIT_LOG_FILE="/var/log/irma-monitoring/console.log"
	/usr/bin/security-check.sh >> "$MONIT_LOG_FILE"
	log "Security report updated"
}

revert_update(){
	if [ -z "$BOOTLIMIT" ]; then
		BOOTLIMIT=$(fw_printenv bootlimit | awk -F'=' '{print $2}')
	fi
	fw_setenv bootcount "$BOOTLIMIT" # bootcount will be bootlimit + 1 after reboot and fallback
}

start_confirmation_test(){
	configuration="/mnt/iris/irma6webserver/enable_update_test"

	if [ -f "$configuration" ] && ! wait_for_confirmation; then
		revert_update; /sbin/reboot; exit 0;
	fi

	finalize_update
}

wait_for_confirmation(){
	CONFIRMATION_PIPE="/tmp/update_confirmation"
	rm -f "$CONFIRMATION_PIPE" # clean pipe
	mkfifo "$CONFIRMATION_PIPE"
	chown irma_webserver "$CONFIRMATION_PIPE" # share pipe with webserver
	log "Waiting for update response..."
	while true
	do
		if read -r line <$CONFIRMATION_PIPE; then
			log "Response received: $line"
			if [ "$line" = 'confirmed' ]; then
				rm -f "$CONFIRMATION_PIPE"
				return 0
			elif [ "$line" = 'rejected' ]; then
				rm -f "$CONFIRMATION_PIPE"
				return 1
			fi
		fi
	done
	return 0
}

finalize_update(){
	# Run reset_uboot_envs first to avoid switching back 
	# to the old firmware in the case of a perfectly timed power cut
	# start_alt_fw_update can be executed on the following boots
	reset_uboot_envs

	remove_userdata_sync_flag
	start_alt_fw_update
}

start_alt_fw_update(){
	if is_alt_fw_update_required; then
		if update_alternative_firmware; then
			sync
			log "Alternative firmware update successful"
		else
			log "Alternative firmware update failed"
		fi
		update_security_report
	fi

	# config/userdata is always synced, in case of rootfs with the same roothash
	# copy only necessary files using rsync 
	if update_alternative_userdata; then
		log "Alternative config update successful"
	else
		log "Alternative config update failed"
	fi
}

remove_userdata_sync_flag(){
	# allow A/B config synchronization in initramfs
	SYNC_FILE="/mnt/iris/userdata_synced"
	rm -f $SYNC_FILE
}


# skip on NFS boot to avoid unecessary reboots
if findmnt / -t nfs4 > /dev/null; then
	log "skipped because of NFS boot"
	exit 0
fi

get_firmware_bootpath

# Check if everything is still ok after update on reboot
PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')

if [ "$PENDING_UPDATE" = "1" ]; then
	BOOTCOUNT=$(fw_printenv bootcount | awk -F'=' '{print $2}')
	BOOTLIMIT=$(fw_printenv bootlimit | awk -F'=' '{print $2}')
	USTATE=$(fw_printenv ustate | awk -F'=' '{print $2}')

	if [ "$BOOTCOUNT" -le "$BOOTLIMIT" ] && [ "$USTATE" = 2 ] ; then
		# test new firwmare
		power_on_selftest || { /sbin/reboot; exit 1; }
		start_confirmation_test &
	else
		# on fallback always reset
		log "Update failed: fallback to boot: $CUR_FW_SUFFIX"
		finalize_update &
	fi
else
	# Check if alternative firmware update is needed
	start_alt_fw_update &
fi
