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
	exists openssl
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
	ROOT_HASH_SIGNATURE="${ROOT_HASH}.signature"

	VERITY_NAME="verity-rootfs${FIRMWARE_SUFFIX}"
	VERITY_DEV="/dev/mapper/${VERITY_NAME}"

	DECRYPT_NAME="decrypted-irma6lvm-rootfs${FIRMWARE_SUFFIX}"
	DECRYPT_ROOT_DEV="/dev/mapper/${DECRYPT_NAME}"
}

unlock_device() {
	# Add Black key to keyring
	caam-keygen import $KEYSTORE/caam/volumeKey.bb importKey
	keyctl padd logon logkey: @us < $KEYSTORE/caam/importKey

	# Remove the volume from previous failed run
	if [ -b "$DECRYPT_ROOT_DEV" ]; then
		lock_device
	fi

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

verify_roothash_signature() {
	PUBKEY="/etc/iris/signing/roothash-public-key.pem"
	/usr/bin/openssl dgst -sha256 -verify "${PUBKEY}" -signature "${ROOT_HASH_SIGNATURE}" "${ROOT_HASH}" || exit 1
}

create_symlinks() {
	ln -sf "$KERNEL_DEV" /dev/swu_kernel || exit 1
	ln -sf "$DECRYPT_ROOT_DEV" /dev/swu_rootfs || exit 1
	ln -sf "$ROOT_HASH_DEV" /dev/swu_hash_dev || exit 1
	ln -sf "$ROOT_HASH" /dev/swu_roothash || exit 1
	ln -sf "$ROOT_HASH_SIGNATURE" /dev/swu_roothash_signature || exit 1
}

remove_symlinks() {
	rm -f /dev/swu_*
}

mount_keystore() {
	if ! grep -qs "${KEYSTORE}" /proc/mounts; then
		mount -t vfat ${KEYSTORE_DEV} ${KEYSTORE} || exit 1
	fi
}

umount_keystore() {
	umount ${KEYSTORE}
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
	lock_device
	verify_roothash_signature
	remove_symlinks
	umount_keystore
	exit 0
fi
