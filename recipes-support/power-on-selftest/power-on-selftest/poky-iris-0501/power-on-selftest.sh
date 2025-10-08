#!/bin/sh

TAG=$0

log() {
	logger -t "$TAG" "$1"
	echo "$TAG $1"
}

exists() {
	command -v "$1" >/dev/null 2>&1 || { log "ERROR: $1 not found"; return 1; }
}

power_on_selftest() {
	# Check that all necessary tools are available and running
	tools="nginx WebInterfaceServer swupdate count_von_count i6ls"
	log "[STARTED] power on self test started!"
	for tool in $tools; do
		exists "$tool" || return 1
		retries=5
		while [ "$retries" -gt 0 ]; do
			if pgrep -f "(^|/)${tool}($| )" >/dev/null 2>&1; then
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
	emmc_dev="/dev/mmcblk0"
	if grep -q 'linuxboot_b' /proc/cmdline; then
		CUR_FITIMAGE_DEV=${emmc_dev}p3
		ALT_FITIMAGE_DEV=${emmc_dev}p2
		CUR_FW_SUFFIX="b"
		ALT_FW_SUFFIX="a"
	else
		CUR_FITIMAGE_DEV=${emmc_dev}p2
		ALT_FITIMAGE_DEV=${emmc_dev}p3
		CUR_FW_SUFFIX="a"
		ALT_FW_SUFFIX="b"
	fi
}

update_alternative_firmware() {
	err=0
	log "Start updating alternative firmware: $ALT_FW_SUFFIX"

	# Update alternative fitImage partition
	mkdir /tmp/alt_fitimage_dev
	mount -t ext4 -o ro "$CUR_FITIMAGE_DEV" /boot
	mount -t ext4 -o rw,noatime "$ALT_FITIMAGE_DEV" /tmp/alt_fitimage_dev
	cp /boot/fitImage.signed /tmp/alt_fitimage_dev/fitImage.signed || \
		{ log "Error: Failed to copy alternative fitImage"; err=1; }
	umount /boot /tmp/alt_fitimage_dev
	rm -rf /tmp/alt_fitimage_dev
	[ "$err" -eq 0 ] || return "$err"

	# Resize the rootfs volume before copying
	# Read new volume size from current rootfs volume (trim leading spaces from lvs output), compare with size of alternative rootfs volume
	new_size=$(lvs "/dev/mapper/matrixlvm-rootfs_${CUR_FW_SUFFIX}" -o LV_SIZE --noheadings --units B --nosuffix | sed 's/^ *//g')
	alt_size=$(lvs "/dev/mapper/matrixlvm-rootfs_${ALT_FW_SUFFIX}" -o LV_SIZE --noheadings --units B --nosuffix | sed 's/^ *//g')

	# Resize alternate rootfs volume
	if [ "$new_size" != "$alt_size" ]; then
		lvresize --autobackup n --force --yes --quiet -L "$new_size"B "/dev/mapper/matrixlvm-rootfs_${ALT_FW_SUFFIX}" 2> /dev/null || \
			{ log "Error: Failed to resize alternative rootfs volume"; err=1; }
	fi
	vgmknodes

	[ "$err" -eq 0 ] || return "$err"

	# Update alternative rootfs and rootfs hashtree volumes
	dd if="/dev/mapper/matrixlvm-rootfs_${CUR_FW_SUFFIX}" of="/dev/mapper/matrixlvm-rootfs_${ALT_FW_SUFFIX}" bs=10M >/dev/null 2>&1 || \
		{ log "Error: Failed to copy alternative rootfs"; err=1; return "$err"; }
	dd if="/dev/mapper/matrixlvm-rootfs_${CUR_FW_SUFFIX}_hash" of="/dev/mapper/matrixlvm-rootfs_${ALT_FW_SUFFIX}_hash" bs=10M >/dev/null 2>&1 || \
		{ log "Error: Failed to copy alternative rootfs hash device"; err=1; return "$err"; }

	# Update alternative roothash.signature
	mount -t ext4 -o rw,noatime /dev/mapper/matrixlvm-keystore /mnt/keystore
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash.signature" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash.signature" || \
		{ log "Error: Failed to copy alternative roothash.signature"; err=1; }

	# Update lastly the roothash, which is used as parameter verify if the alt rootfs needs to be updated
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash" || \
		{ log "Error: Failed to copy alternative roothash"; err=1; }
	umount /mnt/keystore
	sync
	return "$err"
}

rsync_alternative_userdata() {
	log "Synchronizing config from ${CUR_FW_SUFFIX} to ${ALT_FW_SUFFIX}"
	err=0

	dmsetup create decrypted-matrixlvm-userdata_${ALT_FW_SUFFIX} --table "0 $(blockdev --getsz /dev/mapper/matrixlvm-userdata_${ALT_FW_SUFFIX}) crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 /dev/mapper/matrixlvm-userdata_${ALT_FW_SUFFIX} 0 1 sector_size:4096"

	# sync userdata A and B
	USERDATA_MOUNTP="/tmp/userdata_${ALT_FW_SUFFIX}"
	mkdir -p $USERDATA_MOUNTP
	mount -t ext4 -o rw,noatime /dev/mapper/decrypted-matrixlvm-userdata_${ALT_FW_SUFFIX} $USERDATA_MOUNTP || err=1
	rsync -a --delete /mnt/iris/ $USERDATA_MOUNTP || err=1
	umount $USERDATA_MOUNTP
	rm -rf $USERDATA_MOUNTP

	sleep 1 # workaround for removing without busy errors
	dmsetup remove "decrypted-matrixlvm-userdata_${ALT_FW_SUFFIX}"

	return "$err"
}

# return values
# 0: update required
# 1: update not required
is_alt_fw_update_required() {
	ret=1

	# Alternative firmware needs an update if roothash differs
	mount -t ext4 -o ro /dev/mapper/matrixlvm-keystore /mnt/keystore
	if ! cmp -s /mnt/keystore/rootfs_a_roothash /mnt/keystore/rootfs_b_roothash; then
		ret=0
	fi
	umount /mnt/keystore
	return "$ret"
}

update_security_report(){
	# update the security report since synced A/B partitions are a security requirement
	/usr/bin/security-check.sh
	log "Security report updated"
}

check_alt_fw_update() {
	if is_alt_fw_update_required; then
		result=$(update_alternative_firmware && echo "successful" || echo "failed")
		log "Alternative firmware update $result"
		update_security_report
	fi

	# config/userdata is always synced, in case of rootfs with the same roothash
	# copy only necessary files using rsync
	result=$(rsync_alternative_userdata && echo "successful" || echo "failed")
	log "Alternative config update $result"

	# clear lock file
	rm -f "$LOCK_FILE"
}

reset_uboot_envs() {
	TMP_ENV_FILE="/tmp/reset_update_envs"

	# Always set firmware to the current one
	# Default to firmware=0 if value is invalid
	grep -q 'linuxboot_b' /proc/cmdline && firmware=1 || firmware=0
	printf "bootcount=0\nupgrade_available=\nustate=\nfirmware=%s\n" "$firmware" > "$TMP_ENV_FILE"

	# Use a temp file to write u-boot-env's in one go
	fw_setenv -s "$TMP_ENV_FILE"
	rm "$TMP_ENV_FILE"
}

finalize_update() {
	# Run reset_uboot_envs first to avoid switching back 
	# to the old firmware in the case of a perfectly timed power cut
	# check_alt_fw_update can be executed on the following boots
	reset_uboot_envs

	# remove userdata sync flag
	rm -f "/mnt/iris/userdata_synced"

	check_alt_fw_update
}

wait_for_confirmation() {
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

revert_update() {
	if [ -z "$BOOTLIMIT" ]; then
		BOOTLIMIT=$(fw_printenv bootlimit | awk -F'=' '{print $2}')
	fi
	fw_setenv bootcount "$BOOTLIMIT" # bootcount will be bootlimit + 1 after reboot and fallback
}

start_confirmation_test() {
	configuration="/mnt/iris/irma6webserver/enable_update_test"

	if [ -f "$configuration" ] && ! wait_for_confirmation; then
		revert_update; /sbin/reboot; exit 0;
	fi

	finalize_update
}

# skip on NFS boot to avoid unecessary reboots
if findmnt / -t nfs4 > /dev/null; then
	log "skipped because of NFS boot"
	exit 0
fi

get_firmware_bootpath

# Check if everything is still ok after update on reboot
PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')

LOCK_FILE="/tmp/power_on_selftest.lock"
touch "$LOCK_FILE" # lock file is removed in check_alt_fw_update() or by reboot

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
		log "Update failed: booted on fallback firmware: $CUR_FW_SUFFIX"
		finalize_update &
	fi
else
	# Check if alternative firmware update is needed
	check_alt_fw_update &
fi
