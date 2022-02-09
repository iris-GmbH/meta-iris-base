#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

EMMC_DEV="/dev/mmcblk2"

get_next_fw() {
	ROOT_CMD=$(tr ' ' '\n' < /proc/cmdline | grep "^root=")
	ROOT=$(echo "$ROOT_CMD" | sed -e 's/root=//')

	if [ "$ROOT" = "/dev/nfs" ]; then
		echo "Detected nfs root; flash firmware a"
		FW_NEW="a"
		FW_OLD="b"
	else
		ROOTP=$(sfdisk -J $EMMC_DEV | jq 'first(.partitiontable.partitions[] | select (.node == "'"$ROOT"'") | .name)' -r)
		ROOTF=$(echo "$ROOTP" | sed -e 's/rootfs_//')
		if [ "$ROOTF" = "a" ]; then
			FW_NEW="b"
			FW_OLD="a"
		else
			FW_NEW="a"
			FW_OLD="b"
		fi
		echo "Currently on firmware $FW_OLD; flash firmware $FW_NEW"
	fi
}

get_fw_devices() {
	SWU_DEV_ROOTFS=$(sfdisk -J $EMMC_DEV | jq 'first(.partitiontable.partitions[] | select ((.name!=null) and (.name=="rootfs_'$FW_NEW'")) | .node)' -r)
	SWU_DEV_KERNEL=$(sfdisk -J $EMMC_DEV | jq 'first(.partitiontable.partitions[] | select ((.name!=null) and (.name=="linuxboot_'$FW_NEW'")) | .node)' -r)

	if [ -z "$SWU_DEV_ROOTFS" ]; then
		echo "Could not locate rootfs partition for firmware $FW_NEW"; exit 10;
	fi
	if [ -z "$SWU_DEV_KERNEL" ]; then
		echo "Could not locate boot partition for firmware $FW_NEW"; exit 10;
	fi
}

get_boot_partnum() {
	BOOT_OLD=$(sfdisk -J $EMMC_DEV | jq 'first(.partitiontable.partitions[] | select ((.name!=null) and (.name=="linuxboot_'$FW_OLD'")) | .node)' -r)
	BOOT_NEW=$(sfdisk -J $EMMC_DEV | jq 'first(.partitiontable.partitions[] | select ((.name!=null) and (.name=="linuxboot_'$FW_NEW'")) | .node)' -r)

	SWU_BOOTP_OLD=$(echo "$BOOT_OLD" | sed -e "s;$EMMC_DEV.;;")
	SWU_BOOTP_NEW=$(echo "$BOOT_NEW" | sed -e "s;$EMMC_DEV.;;")

	if [ -z "$SWU_BOOTP_OLD" ]; then
		echo "Could not locate boot partition for firmware $FW_OLD"; exit 10;
	fi
	if [ -z "$SWU_BOOTP_NEW" ]; then
		echo "Could not locate boot partition for firmware $FW_NEW"; exit 10;
	fi
}

if [ "$1" = "preinst" ]; then
	get_next_fw
	get_fw_devices
	ln -sf "$SWU_DEV_KERNEL" /dev/swu_kernel
	ln -sf "$SWU_DEV_ROOTFS" /dev/swu_rootfs
fi

if [ "$1" = "postinst" ]; then
	get_next_fw
	rm /dev/swu_kernel
	rm /dev/swu_rootfs
	get_boot_partnum
	#TODO: The two calls to sfdisk are not atomic and not failsafe, we need a better way
	sfdisk --part-attrs $EMMC_DEV "$SWU_BOOTP_NEW" "LegacyBIOSBootable"
	sfdisk --part-attrs $EMMC_DEV "$SWU_BOOTP_OLD" ""
	#TODO: Set U-Boot env variables to indicate an update
fi
