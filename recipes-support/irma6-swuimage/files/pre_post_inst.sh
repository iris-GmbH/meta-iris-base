#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

TAG=$0

log() {
	logger -t "$TAG" "$1"
}

exists() {
	command -v "$1" >/dev/null 2>&1 || { log "ERROR: $1 not found"; exit 1; }
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
	log "Update firmware${FIRMWARE_SUFFIX}"
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

	# get encryption key for decrypting
	KEY=$(cut -d' ' -f1 < /mnt/iris/swupdate/encryption.key)
	# use iv from new sw-description
	IV=$(grep ivt /tmp/sw-description | cut -d'"' -f2 | head -1)
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
		log "Could not locate boot partition for firmware${FIRMWARE_SUFFIX}"; exit 1;
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

imx_fuse_read () {
	idx=${1}	# index = bank * 4 + word
	count=${2}	# count = number of words to be read

	ocotp_patch=$(find /sys/bus/ -name "imx-ocotp0")
	[ -z ${ocotp_patch} ] && { log "No FUSE support!"; exit 1; }
	ocotp_file=${ocotp_patch}/nvmem

	dd if=${ocotp_file} bs=4 count=${count} skip=${idx} 2>/dev/null | hexdump -e '"0x%04x\n"'
}


check_hab_srk() {
	key_type="ecc"
	key_length=521
	n_of_srks=4

	# check if secure boot is activated
	boot_cfg=$(imx_fuse_read 7 1)
	if [ "$(( 0x02000000 & boot_cfg ))" -eq 0 ]; then
 		log "Secure boot is not activated, skipping SRK fuses verification"
 		return
	fi

	# read SRK fuses
	srk_count=$(( 2*n_of_srks ))
	srk_fuses=$(imx_fuse_read 24 $srk_count)

	# read flash.bin SRKs
	flashbin_file=$(cat /tmp/sw-description | tr '\n' ' ' | grep -o '{[^}]*device = "/dev/swu_bootloader"[^}]*}' | grep -o 'filename = "[^"]*";' | cut -d'"' -f 2)
	flashbin_file="/tmp/$flashbin_file"
	flashbin_file_decrypted="/tmp/imx-boot.signed_dec"
	if [ ! -e "$flashbin_file" ]; then
		log "File $flashbin_file not present, cannot verify bootloader SRKs"; exit 1;
	fi

	openssl enc -d -aes-256-cbc -K "$KEY" -iv "$IV" -in $flashbin_file > "$flashbin_file_decrypted"
	(cd /tmp/ && csf_parser -s "$flashbin_file_decrypted" > /dev/null 2>&1)
	(cd /tmp/ && createSRKFuses output/SRKTable.bin "$n_of_srks" "$key_length" "$key_type" > /dev/null 2>&1)
	srk_bootloader=$(hexdump -e '"0x%04x\n"' /tmp/SRK_fuses.bin)

	rm -rf /tmp/output/ /tmp/SRK_fuses.bin "$flashbin_file_decrypted"

	if [ "$srk_bootloader" != "$srk_fuses" ]; then
		log "Aborting, SRK Bootloader does not match SRK Fuse!"
		log "SRK Bootloader: $srk_bootloader"
		log "SRK Fuse: $srk_fuses"
		exit 1;
	fi

	log "SRK Bootloader verification passed"
}

resize_lvm() {
	# suppress lvm tool warnings regarding closing of all file descriptors
	export LVM_SUPPRESS_FD_WARNINGS=1

	# get new compressed/encrypted rootfs
	rootfs_file=$(cat /tmp/sw-description | tr '\n' ' ' | grep -o '{[^}]*device = "/dev/swu_rootfs"[^}]*}' | grep -o 'filename = "[^"]*";' | cut -d'"' -f 2)
	rootfs_file="/tmp/$rootfs_file"
	if [ ! -e "$rootfs_file" ]; then
		log "Could not find new rootfs during logical volume resize!"; exit 1;
	fi

	# get current rootfs size
	cur_size=$(lvs --select "lv_name = rootfs$FIRMWARE_SUFFIX" -o LV_SIZE --units B --nosuffix --noheadings | cut -c3-)

	# get new rootfs size
	new_size=$(openssl enc -d -aes-256-cbc -K "$KEY" -iv "$IV" -in "$rootfs_file" | zcat | wc -c)
	if [ $new_size -eq 0 ]; then
		log "Could not retrieve new rootfs size during logical volume resize!"; exit 1;
	fi

	# mount over read-only /etc/lvm to modify config
	if ! grep -qs /etc/lvm /proc/mounts; then
		mkdir -p /tmp/etc/lvm
		mount --bind /tmp/etc/lvm /etc/lvm
	fi

	log "Resize rootfs logical volume: ${cur_size} to ${new_size}"
	lvresize --force --yes --quiet -L "$new_size"B "$ROOT_DEV" 2> /dev/null
	vgmknodes

	umount /etc/lvm
	rm -R /tmp/etc
}

if [ "$1" = "preinst" ]; then
	cmds_exist
	parse_cmdline
	set_device_names
	mount_keystore
	check_hab_srk
	resize_lvm
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
