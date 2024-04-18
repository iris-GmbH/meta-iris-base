#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

ROOT_MNT="/mnt"
MOUNT="/bin/mount"
UMOUNT="/bin/umount"

if [ -z "${INIT}" ];then
	INIT=/sbin/init
fi

mount_pseudo_fs() {
	echo "Mount pseudo fs"
	${MOUNT} -t devtmpfs none /dev
	${MOUNT} -t tmpfs tmp /tmp
	${MOUNT} -t proc proc /proc
	${MOUNT} -t sysfs sysfs /sys
}

umount_pseudo_fs() {
	echo "Umount pseudo fs"
	${UMOUNT} /dev
	${UMOUNT} /tmp
	${UMOUNT} /proc
	${UMOUNT} /sys
}

parse_cmdline() {
	echo "Kernel cmdline: $(cat /proc/cmdline)"

	# Check if NFS boot is active
	if grep -q 'nfsroot' /proc/cmdline;	then
		NFSPATH=$(grep -Eo "nfsroot=[^ ]*" /proc/cmdline | tr '=' ',' | cut -d',' -f2)
	fi

	if grep -q 'linuxboot_b' /proc/cmdline;	then
		FIRMWARE_SUFFIX="b"
		ALT_FIRMWARE_SUFFIX="a"
	else
		# default to firmware a
		FIRMWARE_SUFFIX="a"
		ALT_FIRMWARE_SUFFIX="b"
	fi
	ROOT_DEV=/dev/mapper/irma6lvm-rootfs_${FIRMWARE_SUFFIX}
	USERDATA_DEV="/dev/mapper/irma6lvm-userdata_${FIRMWARE_SUFFIX}"
	USERDATA_SYM="/dev/mapper/irma6lvm-userdata"
}

echo "Initramfs Bootstrap..."
mount_pseudo_fs

echo "Populate LVM mapper devices"
vgchange -a y
vgmknodes

parse_cmdline
echo "Root mnt   : ${ROOT_MNT}"
echo "Root device: ${ROOT_DEV}"

if [ -n "${NFSPATH}" ]; then
	${MOUNT} -t nfs "${NFSPATH}" ${ROOT_MNT}
	echo "Switching root to Network File System"
else
	${MOUNT} "${ROOT_DEV}" "${ROOT_MNT}"
	echo "Switch root to eMMC"
fi

echo "Create ${USERDATA_SYM} symlink in /etc/fstab"
ln -s "${USERDATA_DEV}" "${USERDATA_SYM}"

umount_pseudo_fs
exec switch_root "${ROOT_MNT}" "${INIT}" "${CMDLINE}"
