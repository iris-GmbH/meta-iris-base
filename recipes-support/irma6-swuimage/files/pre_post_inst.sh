#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

exists() {
	command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 not found"; exit 1; }
}

cmds_exist () {
	exists veritysetup
	exists sfdisk
	exists jq
}

parse_cmdline() {
	if grep -q 'linuxboot_b\|firmware_b' /proc/cmdline; then
		FIRMWARE_SUFFIX="_a"
	else
		# default to update firmware b
		FIRMWARE_SUFFIX="_b"
	fi
	echo "Update firmware${FIRMWARE_SUFFIX}"
}

set_device_names() {
	KEYSTORE_DEV="/dev/mapper/irma6lvm-keystore"
	KEYSTORE="/mnt/keystore"

	ROOT_DEV="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}"
	ROOT_HASH_DEV="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}_hash"
	ROOT_HASH="${KEYSTORE}/rootfs${FIRMWARE_SUFFIX}_roothash"

	VERITY_NAME="verity-rootfs${FIRMWARE_SUFFIX}"
	VERITY_DEV="/dev/mapper/${VERITY_NAME}"

	DECRYPT_NAME="decrypted-irma6lvm-rootfs${FIRMWARE_SUFFIX}"
	DECRYPT_ROOT_DEV="/dev/mapper/${DECRYPT_NAME}"
}

unlock_device() {
	# Add Black key to keyring
	caam-keygen import $KEYSTORE/caam/volumeKey.bb importKey
	keyctl padd logon logkey: @us < $KEYSTORE/caam/importKey

	# TODO: Error handling when alternative boot volume is corrupted
	dmsetup create ${DECRYPT_NAME} --table "0 $(blockdev --getsz ${ROOT_DEV}) \
		crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${ROOT_DEV} 0 1 sector_size:4096" || exit 1
}

lock_device() {
	dmsetup remove ${DECRYPT_NAME}
}

get_bootdev_name() {
	EMMC_DEV="/dev/mmcblk2"
	KERNEL_DEV=$(sfdisk -J $EMMC_DEV | jq 'first(.partitiontable.partitions[] | select ((.name!=null) and (.name=="linuxboot'${FIRMWARE_SUFFIX}'")) | .node)' -r)
	if ! [ -b "$KERNEL_DEV" ]; then
		echo "Could not locate boot partition for firmware${FIRMWARE_SUFFIX}"; exit 1;
	fi
}

create_symlinks() {
	ln -sf "$KERNEL_DEV" /dev/swu_kernel || exit 1
	ln -sf "$DECRYPT_ROOT_DEV" /dev/swu_rootfs || exit 1
	ln -sf "$ROOT_HASH_DEV" /dev/swu_rootfs_hash || exit 1
}

remove_symlinks() {
	rm /dev/swu_kernel
	rm /dev/swu_rootfs
	rm /dev/swu_rootfs_hash
}

mount_keystore() {
	mount -t vfat ${KEYSTORE_DEV} ${KEYSTORE} || exit 1
}

umount_keystore() {
	umount ${KEYSTORE}
}

write_root_hash() {
	# TODO: Unsafe! Store roothash in a secure manner!
	veritysetup format ${DECRYPT_ROOT_DEV} ${ROOT_HASH_DEV} | grep "Root hash:" | grep -Eo "[0-9a-f]+$" > ${ROOT_HASH} || exit 1
	
}

if [ "$1" = "preinst" ]; then
	cmds_exist	
	parse_cmdline
	set_device_names
	mount_keystore
	unlock_device
	get_bootdev_name
	create_symlinks
	exit 0
fi

if [ "$1" = "postinst" ]; then
	parse_cmdline
	set_device_names
	get_bootdev_name
	write_root_hash
	lock_device
	umount_keystore
	remove_symlinks
	exit 0
fi
