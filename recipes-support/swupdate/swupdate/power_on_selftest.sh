#!/bin/sh

TAG=$0

log() {
	logger -t $TAG $1
}

# pidofproc()
. /etc/init.d/functions

ALTERNATIVE_FW_UPDATE_FLAG=/mnt/iris/alternative_fw_needs_update

# Check if everything is still ok after update on reboot
PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
if [ "$PENDING_UPDATE" = "1" ]; then
	# Check that all necessary tools are available and running
	tools="nginx WebInterfaceServer swupdate count_von_count i6ls"
	log "[STARTED] power on self test started!"
	for tool in $tools; do
		if ! pidofproc "$tool" &>/dev/null; then
			log "[FAILED] $tool"; reboot; exit 1;
		fi
		log "[PASSED] $tool"
	done
	log "[PASSED] power on self test"

	# Alternative firmware needs an update if roothash differs
	mount /dev/mapper/irma6lvm-keystore /mnt/keystore
	if ! cmp -s /mnt/keystore/rootfs_a_roothash /mnt/keystore/rootfs_b_roothash; then
		touch "$ALTERNATIVE_FW_UPDATE_FLAG"
	fi
	umount /mnt/keystore

	# Use a temp file to write u-boot-env's in one go
	TMP_ENV_FILE="/tmp/reset_update_envs"
	printf "bootcount=0\nupgrade_available=\nustate=\n" > "$TMP_ENV_FILE"
	fw_setenv -s "$TMP_ENV_FILE"
	rm "$TMP_ENV_FILE"
	log "Update successful complete"
fi

# Update the alternative firmware after success
if [ -f "$ALTERNATIVE_FW_UPDATE_FLAG" ]; then
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
	cp /tmp/cur_fitimage_dev/fitImage.signed /tmp/alt_fitimage_dev/fitImage.signed
	umount /tmp/cur_fitimage_dev /tmp/alt_fitimage_dev
	rm -r /tmp/cur_fitimage_dev /tmp/alt_fitimage_dev

	# Update alternative rootfs and rootfs hashtree volumes
	dd if="/dev/mapper/irma6lvm-rootfs_${CUR_FW_SUFFIX}" of="/dev/mapper/irma6lvm-rootfs_${ALT_FW_SUFFIX}" bs=10M
	dd if="/dev/mapper/irma6lvm-rootfs_${CUR_FW_SUFFIX}_hash" of="/dev/mapper/irma6lvm-rootfs_${ALT_FW_SUFFIX}_hash" bs=10M

	# Update alternative roothash and roothash.signature
	mount /dev/mapper/irma6lvm-keystore /mnt/keystore
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash"
	cp "/mnt/keystore/rootfs_${CUR_FW_SUFFIX}_roothash.signature" "/mnt/keystore/rootfs_${ALT_FW_SUFFIX}_roothash.signature"
	umount /mnt/keystore

	rm "$ALTERNATIVE_FW_UPDATE_FLAG"
fi
