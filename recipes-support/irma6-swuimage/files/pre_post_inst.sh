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

get_device_names() {
	EMMC_DEV="/dev/mmcblk2"
	SWU_KERNEL_DEV=$(sfdisk -J $EMMC_DEV | jq 'first(.partitiontable.partitions[] | select ((.name!=null) and (.name=="linuxboot'${FIRMWARE_SUFFIX}'")) | .node)' -r)
	if [ -z "$SWU_KERNEL_DEV" ]; then
		echo "Could not locate boot partition for firmware${FIRMWARE_SUFFIX}"; exit 10;
	fi

	SWU_ROOT_DEV="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}"
	if [ -z "$SWU_ROOT_DEV" ]; then
		echo "Could not locate $SWU_ROOT_DEV"; exit 10;
	fi

	SWU_ROOT_HASH="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}_hash"
	if [ -z "$SWU_ROOT_HASH" ]; then
		echo "Could not locate $SWU_ROOT_HASH"; exit 10;
	fi
}

create_symlinks() {
	ln -sf "$SWU_KERNEL_DEV" /dev/swu_kernel
	ln -sf "$SWU_ROOT_DEV" /dev/swu_rootfs
	ln -sf "$SWU_ROOT_HASH" /dev/swu_rootfs_hash
}

remove_symlinks() {
	rm /dev/swu_kernel
	rm /dev/swu_rootfs
	rm /dev/swu_rootfs_hash
}

write_root_hash() {
	HASH_DEV="/dev/mapper/irma6lvm-keystore"
	HASH_MNT="/tmp/keystore"
	ROOTHASH="/tmp/keystore/rootfs${FIRMWARE_SUFFIX}_roothash"

	# TODO: Unsafe! Store roothash in a secure manner!
	mkdir -p ${HASH_MNT} || exit 1
	mount -t vfat ${HASH_DEV} ${HASH_MNT} || exit 1
	veritysetup format ${SWU_ROOT_DEV} ${SWU_ROOT_HASH} | grep "Root hash:" | grep -Eo "[0-9a-f]+$" > ${ROOTHASH} || exit 1
	umount ${HASH_MNT} || exit 1
}

if [ "$1" = "preinst" ]; then
	cmds_exist	
	parse_cmdline
	get_device_names
	create_symlinks
	exit 0
fi

if [ "$1" = "postinst" ]; then
	parse_cmdline
	get_device_names
	write_root_hash
	remove_symlinks
	exit 0
fi
