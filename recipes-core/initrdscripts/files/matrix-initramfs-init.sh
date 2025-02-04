#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

ROOT_MNT="/mnt"
MOUNT="/bin/mount"
UMOUNT="/bin/umount"

if [ -z "${INIT}" ];then
	INIT=/sbin/init
fi

mount_pseudo_fs() {
	echo "Mount pseudo fs's"
	${MOUNT} -t devtmpfs none /dev
	${MOUNT} -t proc proc /proc
	${MOUNT} -t sysfs sysfs /sys
}

move_pseudo_fs() {
	echo "Move pseudo fs's"
	${MOUNT} --move /dev ${ROOT_MNT}/dev
	${MOUNT} --move /proc ${ROOT_MNT}/proc
	${MOUNT} --move /sys ${ROOT_MNT}/sys
}

parse_cmdline() {
	CMDLINE="$(cat /proc/cmdline)"
	echo "Kernel cmdline: $CMDLINE"

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
	ROOT_DEV=/dev/mapper/matrixlvm-rootfs_${FIRMWARE_SUFFIX}
	ROOT_HASH_DEV=/dev/mapper/matrixlvm-rootfs_${FIRMWARE_SUFFIX}_hash
	ROOT_HASH=/mnt/keystore/rootfs_${FIRMWARE_SUFFIX}_roothash
	ROOT_HASH_SIGNATURE=/mnt/keystore/rootfs_${FIRMWARE_SUFFIX}_roothash.signature
	VERITY_NAME="verity-rootfs_${FIRMWARE_SUFFIX}"
	VERITY_DEV="/dev/mapper/${VERITY_NAME}"
	DECRYPT_NAME="decrypted-matrixlvm-rootfs_${FIRMWARE_SUFFIX}"
	DECRYPT_ROOT_DEV="/dev/mapper/${DECRYPT_NAME}"
	USERDATA_DEV="/dev/mapper/matrixlvm-userdata_${FIRMWARE_SUFFIX}"
	DECRYPT_USERDATA_NAME="decrypted-matrixlvm-userdata_${FIRMWARE_SUFFIX}"
	DECRYPT_USERDATA_SYM="/dev/mapper/decrypted-matrixlvm-userdata"
	DATASTORE_DEV="/dev/mapper/matrixlvm-datastore"
	DECRYPT_DATASTORE_NAME="decrypted-matrixlvm-datastore"
}

# sync_userdata_from_to
# try to sync config from SRC to DST
# $1: SRC_SUFFIX a/b
# $2: DST_SUFFIX a/b
# will return 1 if failed
sync_userdata_from_to() {
	if [ "$#" -lt 2 ] || [ "$1" = "$2" ]; then
		echo "Error: Can not sync userdata"
		return 1
	fi

	err=0
	SRC_DEC_USER_NAME=decrypted-matrixlvm-userdata_$1
	DST_DEC_USER_NAME=decrypted-matrixlvm-userdata_$2
	SRC_USER_DEV=/dev/mapper/matrixlvm-userdata_$1
	DST_USER_DEV=/dev/mapper/matrixlvm-userdata_$2

	# decrypt existing userdata A/B
	dmsetup create ${SRC_DEC_USER_NAME}  --table "0 $(blockdev --getsz ${SRC_USER_DEV})  crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 ${SRC_USER_DEV}  0 1 sector_size:4096"
	dmsetup create ${DST_DEC_USER_NAME}  --table "0 $(blockdev --getsz ${DST_USER_DEV})  crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 ${DST_USER_DEV}  0 1 sector_size:4096"
	vgmknodes

	# mount userdata A/B
	SRC_MNT_USER=/tmp/userdata_$1
	DST_MNT_USER=/tmp/userdata_$2
	mkdir -p "${SRC_MNT_USER}"  "${DST_MNT_USER}"
	if ! findmnt "${SRC_MNT_USER}" > /dev/null || ! findmnt "${DST_MNT_USER}" > /dev/null; then
		${MOUNT} -t ext4 -o ro "/dev/mapper/${SRC_DEC_USER_NAME}" "${SRC_MNT_USER}" || err=1
		${MOUNT} -t ext4 -o rw "/dev/mapper/${DST_DEC_USER_NAME}" "${DST_MNT_USER}" || err=1
	fi

	if [ "$err" -eq 0 ]; then
		# sync alternative -> current
		# use persitent flag to sync only once
		# sync file is removed on power on self test
		SYNC_FILE=${DST_MNT_USER}/userdata_synced
		if [ ! -f "$SYNC_FILE" ]; then
			echo "Sync Userdata: $1 to $2"
			rsync -a --delete "${SRC_MNT_USER}/" "${DST_MNT_USER}" && touch "$SYNC_FILE"
			sync
		fi
	fi

	${UMOUNT} "${SRC_MNT_USER}" "${DST_MNT_USER}"
	rm -rf "${SRC_MNT_USER}" "${DST_MNT_USER}"
	dmsetup remove "${SRC_DEC_USER_NAME}" "${DST_DEC_USER_NAME}"
}

check_user_data_sync() {
	PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
	BOOTCOUNT=$(fw_printenv bootcount | awk -F'=' '{print $2}')
	BOOTLIMIT=$(fw_printenv bootlimit | awk -F'=' '{print $2}')

	# check if we are updating and not on fallback
	if [ "$PENDING_UPDATE" = "1" ] && [ "$BOOTCOUNT" -le "$BOOTLIMIT" ]; then
		# get config from alternative userdata on update
		sync_userdata_from_to "${ALT_FIRMWARE_SUFFIX}" "${FIRMWARE_SUFFIX}" || exit 1
	fi
}


echo "Initramfs Bootstrap..."
mount_pseudo_fs

echo "Populate LVM mapper devices"
vgchange -a y
vgmknodes

parse_cmdline
echo "Root mnt     : ${ROOT_MNT}"
echo "Root device  : ${ROOT_DEV}"
echo "Crypt device : ${DECRYPT_ROOT_DEV}"
echo "Verity device: ${VERITY_DEV}"

if [ -n "${NFSPATH}" ]; then
	${MOUNT} -t nfs "${NFSPATH}" ${ROOT_MNT}
	echo "Switching root to Network File System"
else
	${MOUNT} -t ext4 -o ro /dev/mapper/matrixlvm-keystore /mnt/keystore
	if ! /usr/bin/openssl dgst -sha256 -verify /etc/iris/signing/roothash-public-key.pem -signature "${ROOT_HASH_SIGNATURE}" "${ROOT_HASH}" ; then
		echo "ERROR: Root hash signature invalid"
		exit 1
	fi
	RH=$(cat "${ROOT_HASH}")

	echo "Add kmk to keystore"
	keyctl add trusted kmk "load $(cat /mnt/keystore/kmk.blob)" @us
	${UMOUNT} /mnt/keystore

	check_user_data_sync

	echo "Unlocking encrypted devices"
	dmsetup create ${DECRYPT_NAME}           --table "0 $(blockdev --getsz ${ROOT_DEV})      crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 ${ROOT_DEV}      0 1 sector_size:4096"
	dmsetup create ${DECRYPT_USERDATA_NAME}  --table "0 $(blockdev --getsz ${USERDATA_DEV})  crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 ${USERDATA_DEV}  0 1 sector_size:4096"
	dmsetup create ${DECRYPT_DATASTORE_NAME} --table "0 $(blockdev --getsz ${DATASTORE_DEV}) crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 ${DATASTORE_DEV} 0 1 sector_size:4096"
	vgmknodes

	echo "Opening verity device: ${DECRYPT_ROOT_DEV}"
	veritysetup open ${DECRYPT_ROOT_DEV} ${VERITY_NAME} ${ROOT_HASH_DEV} "${RH}"
	if ! ${MOUNT} "${VERITY_DEV}" "${ROOT_MNT}" -o ro -t ext4 ; then
		echo "ERROR: Mount root device failed"
		exit 1
	fi
	echo "Switch root to eMMC"
fi

echo "Create ${DECRYPT_USERDATA_SYM} symlink for /etc/fstab"
ln -s "/dev/mapper/${DECRYPT_USERDATA_NAME}" "${DECRYPT_USERDATA_SYM}"

move_pseudo_fs
exec switch_root "${ROOT_MNT}" "${INIT}" "${CMDLINE}"
