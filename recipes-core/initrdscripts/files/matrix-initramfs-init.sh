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
	${MOUNT} -t proc proc /proc
	${MOUNT} -t sysfs sysfs /sys
}

move_pseudo_fs() {
	echo "Umount pseudo fs"
	${MOUNT} --move /dev ${ROOT_MNT}/dev
	${MOUNT} --move /proc ${ROOT_MNT}/proc
	${MOUNT} --move /sys ${ROOT_MNT}/sys
}

parse_cmdline() {
	CMDLINE="$(cat /proc/cmdline)"
	echo "Kernel cmdline: $CMDLINE)"

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
	ROOT_HASH_DEV=/dev/mapper/irma6lvm-rootfs_${FIRMWARE_SUFFIX}_hash
	ROOT_HASH=/mnt/keystore/rootfs_${FIRMWARE_SUFFIX}_roothash
	ROOT_HASH_SIGNATURE=/mnt/keystore/rootfs_${FIRMWARE_SUFFIX}_roothash.signature
	VERITY_NAME="verity-rootfs_${FIRMWARE_SUFFIX}"
	VERITY_DEV="/dev/mapper/${VERITY_NAME}"
	USERDATA_DEV="/dev/mapper/irma6lvm-userdata_${FIRMWARE_SUFFIX}"
	USERDATA_SYM="/dev/mapper/irma6lvm-userdata"
}

echo "Initramfs Bootstrap..."
mount_pseudo_fs

echo "Populate LVM mapper devices"
vgchange -a y
vgmknodes

parse_cmdline
echo "Root mnt     : ${ROOT_MNT}"
echo "Root device  : ${ROOT_DEV}"
echo "Verity device: ${VERITY_DEV}"

if [ -n "${NFSPATH}" ]; then
	${MOUNT} -t nfs "${NFSPATH}" ${ROOT_MNT}
	echo "Switching root to Network File System"
else
	${MOUNT} /dev/mapper/irma6lvm-keystore /mnt/keystore
	if ! /usr/bin/openssl dgst -sha256 -verify /etc/iris/signing/roothash-public-key.pem -signature "${ROOT_HASH_SIGNATURE}" "${ROOT_HASH}" ; then
		echo "ERROR: Root hash signature invalid"
		exit 1
	fi
	RH=$(cat "${ROOT_HASH}")
	${UMOUNT} /mnt/keystore

	echo "Opening verity device: ${ROOT_DEV}"
	veritysetup open ${ROOT_DEV} ${VERITY_NAME} ${ROOT_HASH_DEV} "${RH}"
	if ! ${MOUNT} "${VERITY_DEV}" "${ROOT_MNT}" -o ro ; then
		echo "ERROR: Mount root device failed"
		exit 1
	fi
	echo "Switch root to eMMC"
fi

echo "Create ${USERDATA_SYM} symlink in /etc/fstab"
ln -s "${USERDATA_DEV}" "${USERDATA_SYM}"

move_pseudo_fs
exec switch_root "${ROOT_MNT}" "${INIT}" "${CMDLINE}"
