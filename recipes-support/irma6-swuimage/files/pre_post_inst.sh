#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

TAG=$0

log() {
	logger -t "$TAG" "$1"
}

log_to_website() {
	# SWUpdate captures stdout and displays it on the website
	echo "$1"
	log "$1"
}

exists() {
	command -v "$1" >/dev/null 2>&1 || { log "ERROR: $1 not found"; exit 1; }
}

check_installed_version() {
	localversion=$(sed -ne '/^VERSION=/s/^VERSION=[^0-9]*\([0-9]\+.[0-9]\+.[0-9]\+\)[^0-9]*.*/\1/p' /etc/os-release)
	# Hack for Dunfell-Kirkstone Power Safe Update: check if installed firmware is at least $minimalversion
	minimalversion="2.1.5"
	printf '%s\n%s\n' "$minimalversion" "$localversion" | sort --check=quiet --version-sort || { log_to_website "This update requires at least firmware version $minimalversion to be installed."; exit 1; }
}

cmds_exist () {
	exists dmsetup
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

	DECRYPT_NAME="decrypted-irma6lvm-rootfs${FIRMWARE_SUFFIX}"
	DECRYPT_ROOT_DEV="/dev/mapper/${DECRYPT_NAME}"

	# get encryption key for decrypting
	KEY=$(cut -d' ' -f1 < /mnt/iris/swupdate/encryption.key)
	# use iv from new sw-description
	IV=$(grep ivt /tmp/sw-description | cut -d'"' -f2 | head -1)

	# suppress lvm tool warnings regarding closing of all file descriptors
	export LVM_SUPPRESS_FD_WARNINGS=1
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
	[ -z "${ocotp_patch}" ] && { log "No FUSE support!"; exit 1; }
	ocotp_file=${ocotp_patch}/nvmem

	dd if="${ocotp_file}" bs=4 count="${count}" skip="${idx}" 2>/dev/null | hexdump -e '"0x%04x\n"'
}


check_hab_srk() {
	key_type="ecc"
	key_length=521
	n_of_srks=4

	# images to be verified for SRK signature
	signed_images="/tmp/imx-boot.signed /tmp/irma6-fitimage.itb.signed"

	# check if secure boot is activated
	boot_cfg=$(imx_fuse_read 7 1)
	if [ "$(( 0x02000000 & boot_cfg ))" -eq 0 ]; then
		log "Secure boot is not activated, skipping SRK fuses verification"
		return
	fi

	# read SRK fuses
	srk_count=$(( 2*n_of_srks ))
	srk_fuses=$(imx_fuse_read 24 $srk_count)

	for signed_image in $signed_images
	do
		if [ ! -e "$signed_image" ]; then
			log "File $signed_image not present, cannot verify SRKs"; exit 1;
		fi

		# decrypt image to read SRKs
		file_decrypted="/tmp/file_decrypted"
		openssl enc -d -aes-256-cbc -K "$KEY" -iv "$IV" -in "$signed_image" > "$file_decrypted"

		# read SRKs from image
		(cd /tmp/ && csf_parser -s "$file_decrypted" > /dev/null 2>&1)
		(cd /tmp/ && createSRKFuses output/SRKTable.bin "$n_of_srks" "$key_length" "$key_type" > /dev/null 2>&1)
		srk_image=$(hexdump -e '"0x%04x\n"' /tmp/SRK_fuses.bin)

		# clean up
		rm -rf /tmp/output/ /tmp/SRK_fuses.bin "$file_decrypted"

		if [ "$srk_image" != "$srk_fuses" ]; then
			log "Aborting, SRK $signed_image does not match SRK Fuse!"
			log "SRK Image: $srk_image"
			log "SRK Fuse: $srk_fuses"
			exit 1;
		fi
	done

	log "SRK verification passed"
}

check_identity() {
	SENSOR_KEY="/mnt/iris/identity/sensor.key"
	SENSOR_CRT="/mnt/iris/identity/sensor.crt"

	if ! [ -f "$SENSOR_KEY" ] || ! [ -f "$SENSOR_CRT" ]; then
		log "Device has no identity certificate or key"; exit 1;
	fi
}

resize_lvm() {
	# get new compressed/encrypted rootfs
	rootfs_file=$(< /tmp/sw-description tr '\n' ' ' | grep -o '{[^}]*device = "/dev/swu_rootfs"[^}]*}' | grep -o 'filename = "[^"]*";' | cut -d'"' -f 2)
	rootfs_file="/tmp/$rootfs_file"
	if [ ! -e "$rootfs_file" ]; then
		log "Could not find new rootfs during logical volume resize!"; exit 1;
	fi

	# get current rootfs size
	cur_size=$(lvs --select "lv_name = rootfs$FIRMWARE_SUFFIX" -o LV_SIZE --units B --nosuffix --noheadings | cut -c3-)

	# get new rootfs size
	new_size=$(openssl enc -d -aes-256-cbc -K "$KEY" -iv "$IV" -in "$rootfs_file" | zcat | wc -c)
	if [ "$new_size" -eq 0 ]; then
		log "Could not retrieve new rootfs size during logical volume resize!"; exit 1;
	fi

	log "Resize rootfs logical volume: ${cur_size} to ${new_size}"
	lvresize --autobackup n --force --yes --quiet -L "$new_size"B "$ROOT_DEV" 2> /dev/null
	vgmknodes
}

move_userdata_config() {
	# If old webserver dir exists, copy to new location, no matter what
	# Old location will be deleted after successfull power on selftest
	if [ -d "/mnt/iris/counter/webserver" ]; then
		rm -rf "/mnt/iris/irma6webserver"
		cp -a "/mnt/iris/counter/webserver" "/mnt/iris/irma6webserver"
	fi

	# Move uuid file if it is present
	if [ -f "/mnt/iris/uuid" ]; then
		cp -a "/mnt/iris/uuid" "/mnt/iris/counter/uuid"
		rm -f "/mnt/iris/uuid"
	fi
}

create_webserver_symlinks() {
	if [ ! -L "/mnt/iris/webtls" ]; then
		log "Create default webtls symlink"
		ln -sf /mnt/iris/identity /mnt/iris/webtls || exit 1
	fi
	if [ ! -L "/mnt/iris/nts" ]; then
		log "Create default chrony symlink"
		ln -sf /mnt/iris/identity /mnt/iris/nts || exit 1
	fi
	# if "disable_https" parameter has version 1.0, we must overwrite default_server with https
	if [ -f "/mnt/iris/counter/config_customer.json" ]; then
		is_old_version=$(jq '.sets.IRMA6_Customer.parameters["pa.communication.disable_https"]["version"] == "1.0"' "/mnt/iris/counter/config_customer.json")
		if [ "$is_old_version" = "true" ]; then
			# remove link here, the following lines will recreate link
			rm "/mnt/iris/nginx/sites-enabled/default_server"
		fi
	fi
	if [ ! -L "/mnt/iris/nginx/sites-enabled/default_server" ]; then
		log "Create default webserver server conf symlink"
		mkdir -p /mnt/iris/nginx/sites-enabled || exit 1
		ln -sf /etc/nginx/sites-available/reverse_proxy_https.conf /mnt/iris/nginx/sites-enabled/default_server  || exit 1
	fi
}

create_userdata_mirror(){
	if ! lvs "/dev/irma6lvm/userdata${FIRMWARE_SUFFIX}" > /dev/null 2>&1; then
		# create alt userdata volume, if needed
		lvcreate -y --autobackup n -n "userdata${FIRMWARE_SUFFIX}" -L 512MB irma6lvm
		dmsetup -v create decrypted-irma6lvm-userdata${FIRMWARE_SUFFIX} --table \
			"0 $(blockdev --getsz /dev/mapper/irma6lvm-userdata${FIRMWARE_SUFFIX}) \
			crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-userdata${FIRMWARE_SUFFIX} 0 1 sector_size:4096"
		mkfs.ext4 /dev/mapper/decrypted-irma6lvm-userdata${FIRMWARE_SUFFIX}
	else
		# decrypt existing alternative userdata
		dmsetup -v create decrypted-irma6lvm-userdata${FIRMWARE_SUFFIX} --table \
			"0 $(blockdev --getsz /dev/mapper/irma6lvm-userdata${FIRMWARE_SUFFIX}) \
			crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-userdata${FIRMWARE_SUFFIX} 0 1 sector_size:4096"
	fi

	# sync A and B, because alternative fw needs current config
	err=0
	mkdir -p /tmp/userdata${FIRMWARE_SUFFIX}
	mount -t ext4 /dev/mapper/decrypted-irma6lvm-userdata${FIRMWARE_SUFFIX} /tmp/userdata${FIRMWARE_SUFFIX} || err=1
	cp -r /mnt/iris/* /tmp/userdata${FIRMWARE_SUFFIX} || err=1
	
	umount /tmp/userdata${FIRMWARE_SUFFIX}
	rm -rf /tmp/userdata${FIRMWARE_SUFFIX}
	dmsetup remove decrypted-irma6lvm-userdata${FIRMWARE_SUFFIX}

	if ! [ "$err" -eq 0 ] ; then
		exit "$err"
	fi
}

pending_update() {
	PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
	if [ "$PENDING_UPDATE" = "1" ]; then
		log_to_website "Update pending, device reboot required"
		exit 1
	fi
}


if [ "$1" = "preinst" ]; then
	check_installed_version
	pending_update
	cmds_exist
	parse_cmdline
	set_device_names
	mount_keystore
	check_hab_srk
	check_identity
	resize_lvm
	unlock_device
	get_bootdev_name
	create_symlinks
	create_webserver_symlinks
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
	move_userdata_config
	create_userdata_mirror
	exit 0
fi
