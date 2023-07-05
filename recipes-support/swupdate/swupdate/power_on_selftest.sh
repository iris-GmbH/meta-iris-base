#!/bin/sh

TAG=$0

log() {
	logger -t "$TAG" "$1"
	echo "$TAG $1" > /dev/kmsg
}

exists() {
	command -v "$1" >/dev/null 2>&1 || { log "ERROR: $1 not found"; exit 1; }
}

# pidofproc()
. /etc/init.d/functions

ALTERNATIVE_FW_UPDATE_FLAG=/mnt/iris/alternative_fw_needs_update

# lock file can be used by other init scripts for synchronization
LOCK_FILE=/tmp/selftest.lock

power_on_selftest() {
	# Check that all necessary tools are available and running
	tools="nginx WebInterfaceServer swupdate count_von_count i6ls"
	log "[STARTED] power on self test started!"
	for tool in $tools; do
		exists "$tool"
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
			log "[FAILED] power on self test"; reboot; exit 1;
		fi
	done
	log "[PASSED] power on self test"
}

update_alternative_firmware() {
	err=0
	log "Start updating alternative firmware"
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

	# Update alternative roothash and roothash.signature
	mount /dev/mapper/irma6lvm-keystore /mnt/keystore
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash" || \
		{ log "Error: Failed to copy alternative roothash"; err=1; }
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash.signature" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash.signature" || \
		{ log "Error: Failed to copy alternative roothash.signature"; err=1; }
	umount /mnt/keystore

	# Delete obsolete directories that were migrated in pre_post_install script
	rm -rf "/mnt/iris/counter/webserver"

	return "$err";
}

prepare_alternative_fw_update() {
	# Alternative firmware needs an update if roothash differs
	mount /dev/mapper/irma6lvm-keystore /mnt/keystore
	if ! cmp -s /mnt/keystore/rootfs_a_roothash /mnt/keystore/rootfs_b_roothash; then
		touch "$ALTERNATIVE_FW_UPDATE_FLAG"
		sync
	fi
	umount /mnt/keystore
}

reset_uboot_envs() {
	TMP_ENV_FILE="/tmp/reset_update_envs"

	# Always set firmware to the current one, if self test is passed
	# Default to firmware=0 if value is invalid
	grep -q 'linuxboot_b\|firmware_b' /proc/cmdline && firmware=1 || firmware=0
	printf "bootcount=0\nupgrade_available=\nustate=\nfirmware=%s\n" "$firmware" > "$TMP_ENV_FILE"

	# Use a temp file to write u-boot-env's in one go
	fw_setenv -s "$TMP_ENV_FILE"
	rm "$TMP_ENV_FILE"
}

{
touch $LOCK_FILE

# Check if everything is still ok after update on reboot
PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
if [ "$PENDING_UPDATE" = "1" ]; then
	power_on_selftest
	reset_uboot_envs
	prepare_alternative_fw_update
	log "Firmware update successful complete"
fi

# Update the alternative firmware after success
if [ -f "$ALTERNATIVE_FW_UPDATE_FLAG" ]; then
	update_alternative_firmware && rm "$ALTERNATIVE_FW_UPDATE_FLAG" && log "Alternative firmware update complete" || log "Alternative firmware update failed"
fi

rm $LOCK_FILE

} &
