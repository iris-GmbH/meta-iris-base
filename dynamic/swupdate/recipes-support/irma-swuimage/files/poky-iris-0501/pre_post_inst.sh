#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

# suppress lvm tool warnings regarding closing of all file descriptors
export LVM_SUPPRESS_FD_WARNINGS=1

parse_cmdline() {
	if grep -q 'linuxboot_b' /proc/cmdline; then
		FIRMWARE_SUFFIX="a"
		FIRMWARE_SUFFIX_ALT="b"
	else
		# default to update firmware b
		FIRMWARE_SUFFIX="b"
		FIRMWARE_SUFFIX_ALT="a"
	fi
}

set_device_names() {
	KEYSTORE_DEV="/dev/mapper/matrixlvm-keystore"
	KEYSTORE="/mnt/keystore"

	ROOT_DEV="/dev/mapper/matrixlvm-rootfs_${FIRMWARE_SUFFIX}"
	ROOT_HASH_DEV="/dev/mapper/matrixlvm-rootfs_${FIRMWARE_SUFFIX}_hash"
	ROOT_HASH="${KEYSTORE}/rootfs_${FIRMWARE_SUFFIX}_roothash"
	ROOT_HASH_SIGNATURE="${ROOT_HASH}.signature"

	DECRYPT_NAME="decrypted-matrixlvm-rootfs_${FIRMWARE_SUFFIX}"
	DECRYPT_ROOT_DEV="/dev/mapper/${DECRYPT_NAME}"

	# get encryption key for decrypting
	KEY=$(cut -d' ' -f1 < /mnt/iris/swupdate/encryption.key)
	# use iv from new sw-description
	IV=$(grep ivt /tmp/sw-description | cut -d'"' -f2 | head -1)
}

mount_keystore() {
	if ! findmnt ${KEYSTORE}; then
		mount ${KEYSTORE_DEV} ${KEYSTORE} || exit 1
	fi
}

umount_keystore() {
	findmnt ${KEYSTORE} && umount ${KEYSTORE}
}

check_identity() {
	SENSOR_KEY="/mnt/iris/identity/sensor.key"
	SENSOR_CRT="/mnt/iris/identity/sensor.crt"

	if ! [ -f "$SENSOR_KEY" ] || ! [ -f "$SENSOR_CRT" ]; then
		echo "ERROR: Device has no identity certificate or key"; exit 1;
	fi
}

create_symlinks() {
	KERNEL_DEV=$(sfdisk -J /dev/mmcblk0 | jq 'first(.partitiontable.partitions[] | select ((.name!=null) and (.name=="linuxboot_'${FIRMWARE_SUFFIX}'")) | .node)' -r)
	if ! [ -b "$KERNEL_DEV" ]; then
		echo "ERROR: Could not locate boot partition for firmware ${FIRMWARE_SUFFIX}"; exit 1;
	fi

	ln -sf "$KERNEL_DEV" /dev/swu_kernel || exit 1
	ln -sf "$DECRYPT_ROOT_DEV" /dev/swu_rootfs || exit 1
	ln -sf "$ROOT_HASH_DEV" /dev/swu_hash_dev || exit 1
	ln -sf "$ROOT_HASH" /dev/swu_roothash || exit 1
	ln -sf "$ROOT_HASH_SIGNATURE" /dev/swu_roothash_signature || exit 1
}

remove_symlinks() {
	rm -f /dev/swu_kernel
	rm -f /dev/swu_rootfs
	rm -f /dev/swu_hash_dev
	rm -f /dev/swu_roothash
	rm -f /dev/swu_roothash_signature
}

resize_rootfs_lvm() {
	# get new compressed/encrypted rootfs
	rootfs_file=$(< /tmp/sw-description tr '\n' ' ' | grep -o '{[^}]*device = "/dev/swu_rootfs"[^}]*}' | grep -o 'filename = "[^"]*";' | cut -d'"' -f 2)
	rootfs_file="/tmp/$rootfs_file"
	if [ ! -e "$rootfs_file" ]; then
		echo "ERROR: Could not find new rootfs during logical volume resize!"; exit 1;
	fi

	# get current rootfs size
	cur_size=$(lvs --select "lv_name = rootfs$FIRMWARE_SUFFIX" -o LV_SIZE --units B --nosuffix --noheadings | cut -c3-)

	# get new rootfs size
	new_size=$(openssl enc -d -aes-256-cbc -K "$KEY" -iv "$IV" -in "$rootfs_file" | zcat | wc -c)
	if [ "$new_size" -eq 0 ]; then
		echo "ERROR: Could not retrieve new rootfs size during logical volume resize!"; exit 1;
	fi
	if [ "$new_size" != "$cur_size" ]; then
		echo "Resize rootfs logical volume: ${cur_size} to ${new_size}"
		lvresize --autobackup n --force --yes --quiet -L "$new_size"B "$ROOT_DEV" 2> /dev/null # this never returns 0
		vgmknodes
	fi
}

unlock_device() {
	echo "Add kmk to keystore"
	if ! keyctl search @us trusted kmk > /dev/null 2>&1; then
		keyctl add trusted kmk "load $(cat /mnt/keystore/kmk.blob)" @us
	fi

	# Remove the volume from previous failed run
	if [ -b "$DECRYPT_ROOT_DEV" ]; then
		lock_device
	fi

	dmsetup create ${DECRYPT_NAME} --table "0 $(blockdev --getsz ${ROOT_DEV}) \
		crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 ${ROOT_DEV} 0 1 sector_size:4096" || exit 1
}

lock_device() {
	if dmsetup ls | grep -q ${DECRYPT_NAME}; then
		dmsetup remove ${DECRYPT_NAME}
	fi
}

set_upgrade_available() {
	fw_setenv upgrade_available 1 || exit 1
}

pending_update() {
	wait_counter=8 # seconds
	while [ -f "/tmp/power_on_selftest.lock" ]; do
		wait_counter=$((wait_counter - 1))
		echo "WARN: Power on self test is still running"
		if [ "$wait_counter" -eq 0 ]; then
			echo "ERROR: Power on self test is still running. Abort!"
			exit 1
		fi
		sleep 1
	done
}

check_srks() {
	# FIXME: MARE-183
	echo "WARN: check_srks not yet implemented"
}

remove_userdata_sync_files() {
	SYNC_FILE_NAME="userdata_synced"

	USERDATA_ALT_NAME="userdata$FIRMWARE_SUFFIX_ALT"
	USERDATA_ALT_MOUNTP="/tmp/$USERDATA_ALT_NAME"
	USERDATA_ALT_DEV="/dev/mapper/matrixlvm-userdata_${FIRMWARE_SUFFIX_ALT}"

	# remove sync file from current userdata
	rm -f "/mnt/iris/$SYNC_FILE_NAME"

	# remove possible sync file from alternative userdata
	if [ -b "${USERDATA_ALT_DEV}" ]; then
		dmsetup create "${USERDATA_ALT_NAME}" --table "0 $(blockdev --getsz "${USERDATA_ALT_DEV}") \
		crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 ${USERDATA_ALT_DEV} 0 1 sector_size:4096"

		mkdir -p "$USERDATA_ALT_MOUNTP"
		mount "/dev/mapper/${USERDATA_ALT_NAME}" "$USERDATA_ALT_MOUNTP"
		rm -f "$USERDATA_ALT_MOUNTP/$SYNC_FILE_NAME"
		umount "$USERDATA_ALT_MOUNTP"
		rm -rf "$USERDATA_ALT_MOUNTP"
		dmsetup remove "$USERDATA_ALT_NAME"
	fi
}

if [ "$1" = "preinst" ]; then
	pending_update
	parse_cmdline
	echo "Update firmware ${FIRMWARE_SUFFIX}"
	set_device_names
	mount_keystore
	check_srks
	check_identity
	resize_rootfs_lvm
	unlock_device
	create_symlinks
	exit 0
fi

if [ "$1" = "postinst" ]; then
	parse_cmdline
	set_device_names
	lock_device
	umount_keystore
	remove_userdata_sync_files
	set_upgrade_available
	exit 0
fi

if [ "$1" = "failure" ] || [ "$1" = "postfailure" ]; then
	parse_cmdline
	set_device_names
	lock_device
	umount_keystore
	remove_symlinks
	exit 0
fi
