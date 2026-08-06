#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

ROOT_MNT="/mnt"
MOUNT="/bin/mount"
UMOUNT="/bin/umount"
vg=matrixlvm

if [ -z "${INIT}" ];then
    INIT=/sbin/init
fi

# Determine eMMC device e.g. mmcblk0
device="mmcblk0"
for i in 0 1 2; do
    if [ -b "/dev/mmcblk${i}" ]; then
        device="mmcblk${i}"
        break
    fi
done

mount_pseudo_fs() {
    echo "Mount pseudo fs's"
    ${MOUNT} -t devtmpfs none /dev
    ${MOUNT} -t tmpfs tmp /tmp
    ${MOUNT} -t tmpfs tmp /run
    ${MOUNT} -t proc proc /proc
    ${MOUNT} -t sysfs sysfs /sys
}

move_special_devices() {    
    echo "Move pseudo fs's"
    ${MOUNT} --move /dev ${ROOT_MNT}/dev
    ${MOUNT} --move /proc ${ROOT_MNT}/proc
    ${MOUNT} --move /sys ${ROOT_MNT}/sys
    ${MOUNT} --move /run ${ROOT_MNT}/run
}

mount_device_data() {
    DEVICE_DATA_MNT="${ROOT_MNT}/mnt/devicedata"
    DEVICE_DATA_DEV="/dev/mapper/matrixlvm-devicedata"

    if [ ! -d "${DEVICE_DATA_MNT}" ]; then
        echo "ERROR: Missing mountpoint: ${DEVICE_DATA_MNT}"
        return 1
    fi

    if [ ! -e "${DEVICE_DATA_DEV}" ]; then
        echo "ERROR: Devicedata volume is not present: ${DEVICE_DATA_DEV}"
        return 1
    fi

    echo "Mount devicedata: ${DEVICE_DATA_DEV} -> ${DEVICE_DATA_MNT}"
    if ! ${MOUNT} -t ext4 "${DEVICE_DATA_DEV}" "${DEVICE_DATA_MNT}"; then
        echo "ERROR: Failed to mount devicedata: ${DEVICE_DATA_DEV}"
        return 1
    fi
}

mount_device_data_backup() {
    DEVICE_DATA_MNT="${ROOT_MNT}/mnt/devicedata"
    DEVICE_DATA_BACKUP_MNT="/tmp/devicedata-backup"

    if [ ! -d "${DEVICE_DATA_MNT}" ]; then
        echo "ERROR: Missing mountpoint: ${DEVICE_DATA_MNT}"
        return 1
    fi

    mkdir -p "${DEVICE_DATA_BACKUP_MNT}"
    for DEVICE_DATA_BACKUP_DEV in /dev/${device}boot1; do
        [ -b "${DEVICE_DATA_BACKUP_DEV}" ] || continue

        DEVICE_DATA_BACKUP_SIZE=2M
        if ! DETECTED_BACKUP_SIZE=$(blockdev --getsize64 "${DEVICE_DATA_BACKUP_DEV}") ||
           [ -z "${DETECTED_BACKUP_SIZE}" ]; then
            echo "WARNING: Failed to determine backup size; using ${DEVICE_DATA_BACKUP_SIZE}"
        else
            DEVICE_DATA_BACKUP_SIZE="${DETECTED_BACKUP_SIZE}"
        fi

        if ! ${MOUNT} -t ext4 -o ro "${DEVICE_DATA_BACKUP_DEV}" "${DEVICE_DATA_BACKUP_MNT}" 2>/dev/null; then
            continue
        fi

        if [ ! -d "${DEVICE_DATA_BACKUP_MNT}/nvm" ] ||
           [ -z "$(ls -A "${DEVICE_DATA_BACKUP_MNT}/nvm" 2>/dev/null)" ]; then
            ${UMOUNT} "${DEVICE_DATA_BACKUP_MNT}"
            continue
        fi

        echo "Restore devicedata fallback from ${DEVICE_DATA_BACKUP_DEV}"
        if ! ${MOUNT} -t tmpfs -o "size=${DEVICE_DATA_BACKUP_SIZE},mode=0755" devicedata-fallback "${DEVICE_DATA_MNT}"; then
            echo "ERROR: Failed to mount devicedata fallback"
            ${UMOUNT} "${DEVICE_DATA_BACKUP_MNT}"
            return 1
        fi

        if ! cp -r "${DEVICE_DATA_BACKUP_MNT}/nvm" "${DEVICE_DATA_MNT}/"; then
            echo "ERROR: Failed to copy devicedata backup"
            ${UMOUNT} "${DEVICE_DATA_MNT}"
            ${UMOUNT} "${DEVICE_DATA_BACKUP_MNT}"
            return 1
        fi

        if ! ${UMOUNT} "${DEVICE_DATA_BACKUP_MNT}"; then
            echo "ERROR: Failed to unmount devicedata backup"
            ${UMOUNT} "${DEVICE_DATA_MNT}"
            return 1
        fi

        return 0
    done

    echo "ERROR: No usable devicedata backup found"
    return 1
}

mount_runtime_volumes() {
    USERDATA_MNT="${ROOT_MNT}/mnt/iris"
    DATASTORE_MNT="${ROOT_MNT}/mnt/datastore"
    DEVICE_DATA_MNT="${ROOT_MNT}/mnt/devicedata"
    COUNTER_MNT="${ROOT_MNT}/etc/counter"

    for mountpoint in "${USERDATA_MNT}" "${DATASTORE_MNT}" "${DEVICE_DATA_MNT}" "${COUNTER_MNT}"; do
        if [ ! -d "${mountpoint}" ]; then
            echo "ERROR: Missing mountpoint: ${mountpoint}"
            return 1
        fi
    done

    echo "Mount userdata: /dev/mapper/${DECRYPT_USERDATA_NAME} -> ${USERDATA_MNT}"
    ${MOUNT} -t ext4 "/dev/mapper/${DECRYPT_USERDATA_NAME}" "${USERDATA_MNT}" || return 1

    echo "Mount datastore: /dev/mapper/${DECRYPT_DATASTORE_NAME} -> ${DATASTORE_MNT}"
    if ! ${MOUNT} -t ext4 "/dev/mapper/${DECRYPT_DATASTORE_NAME}" "${DATASTORE_MNT}"; then
        ${UMOUNT} "${USERDATA_MNT}"
        return 1
    fi

    if ! mount_device_data; then
        ${UMOUNT} "${DATASTORE_MNT}"
        ${UMOUNT} "${USERDATA_MNT}"
        return 1
    fi

    echo "Bind mount counter config: ${USERDATA_MNT}/counter -> ${COUNTER_MNT}"
    mkdir -p "${USERDATA_MNT}/counter"
    if ! ${MOUNT} --bind "${USERDATA_MNT}/counter" "${COUNTER_MNT}"; then
        ${UMOUNT} "${DEVICE_DATA_MNT}"
        ${UMOUNT} "${DATASTORE_MNT}"
        ${UMOUNT} "${USERDATA_MNT}"
        return 1
    fi
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
    DECRYPT_USERDATA_NAME="decrypted-matrixlvm-userdata"
    DATASTORE_DEV="/dev/mapper/matrixlvm-datastore"
    DECRYPT_DATASTORE_NAME="decrypted-matrixlvm-datastore"
}

pvsn_wipe() {
    sector_size=512 # 512 bytes
    partition_offset=$(cat "/sys/class/block/${device}p5/start")
    erase_size_bytes=$(cat "/sys/class/block/${device}/device/erase_size")
    pe_start_bytes=$(pvs --no-heading --no-suffix -o pe_start --unit B | xargs | sed 's/\.00$//') # first physical extent offset in bytes
    pe_start=$((pe_start_bytes / sector_size))
    erase_size=$((erase_size_bytes / sector_size))
    pv_size=$(pvs --no-heading --no-suffix -o pv_size --unit B | xargs) # physical volume size in bytes
    pe_count=$(pvs --no-heading -o pv_pe_count | xargs) # physical extent count
    pe_size=$((pv_size / pe_count)) # physical extent size in bytes (should be 4 MiB)
    lv_start_pe=$(pvs --no-headings -o seg_pe_ranges --select "lv_name = $1" | sed -e 's/.*:\(.*\)-.*/\1/') # start of logical volume in physical extents
    lv_size_pe=$(pvs --no-headings -o seg_size_pe --select "lv_name = $1" | xargs) # size of logical volume in physical extents

    # convert bytes to mmc sectors (512B per sector)
    start=$((lv_start_pe * pe_size / sector_size + partition_offset + pe_start))
    end=$(((lv_start_pe + lv_size_pe) * pe_size / sector_size + partition_offset + pe_start - 1))

    if [ $((erase_size_bytes % sector_size)) -ne 0 ] || [ $((start % erase_size)) -ne 0 ] || [ $(((end + 1) % erase_size)) -ne 0 ]; then
        echo "Refusing secure erase for $1: range ${start}-${end} is not aligned to erase_size ${erase_size_bytes} bytes"
        exit 1
    fi

    mmc erase secure-erase "$start" "$end" "/dev/${device}"
}

# provisioning flash procedure
pvsn_flash() {
    echo "Initramfs provisioning flash routine started..."

    # Mount keystore
    KEYSTORE_DEV="/dev/mapper/$vg-keystore"
    KEYSTORE="/mnt/keystore"
    ${MOUNT} ${KEYSTORE_DEV} ${KEYSTORE}

    # Generate trusted key and add them to the keyring
    key_id=$(keyctl add trusted kmk "new 32" @us) || echo "Error: Failed to create trusted key kmk"
    keyctl link @us @s || echo "Error: Failed to link user keyring to session keyring"
    keyctl pipe "$key_id" > "${KEYSTORE}/kmk.blob" || echo "Error: Failed to cache trusted key blob in keystore"
    [ -s "${KEYSTORE}/kmk.blob" ] || echo "Error: Cached trusted key blob is empty"
    ${UMOUNT} ${KEYSTORE}

    # Setup encrypted volumes
    dmsetup create "decrypted-$vg-rootfs_a"   --table "0 $(blockdev --getsz "/dev/mapper/$vg-rootfs_a")   crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 /dev/mapper/$vg-rootfs_a   0 1 sector_size:4096"
    dmsetup create "decrypted-$vg-rootfs_b"   --table "0 $(blockdev --getsz "/dev/mapper/$vg-rootfs_b")   crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 /dev/mapper/$vg-rootfs_b   0 1 sector_size:4096"
    dmsetup create "decrypted-$vg-userdata_a" --table "0 $(blockdev --getsz "/dev/mapper/$vg-userdata_a") crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 /dev/mapper/$vg-userdata_a 0 1 sector_size:4096"
    dmsetup create "decrypted-$vg-userdata_b" --table "0 $(blockdev --getsz "/dev/mapper/$vg-userdata_b") crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 /dev/mapper/$vg-userdata_b 0 1 sector_size:4096"
    dmsetup create "decrypted-$vg-datastore"  --table "0 $(blockdev --getsz "/dev/mapper/$vg-datastore")  crypt aes-cbc-essiv:sha256 :32:trusted:kmk 0 /dev/mapper/$vg-datastore  0 1 sector_size:4096"
    vgmknodes

    # Copy rootfs
    dd if="/dev/mapper/$vg-pvsn_rootfs" of="/dev/mapper/decrypted-$vg-rootfs_a"
    dd if="/dev/mapper/$vg-rootfs_a" of="/dev/mapper/$vg-rootfs_b"
    sync

    # Mount and copy userdata A/B
    MOUNTP_USERDATA_A="/mnt/userdata_a"
    MOUNTP_USERDATA_B="/mnt/userdata_b"
    MOUNTP_USERDATA_PVSN="/mnt/pvsn_userdata"
    mkfs.ext4 "/dev/mapper/decrypted-$vg-userdata_a"
    mkfs.ext4 "/dev/mapper/decrypted-$vg-userdata_b"
    mkfs.ext4 "/dev/mapper/decrypted-$vg-datastore"
    mkdir -p $MOUNTP_USERDATA_PVSN
    mkdir -p $MOUNTP_USERDATA_A
    mkdir -p $MOUNTP_USERDATA_B

    mount -t ext4 "/dev/mapper/$vg-pvsn_userdata" $MOUNTP_USERDATA_PVSN
    mount -t ext4 "/dev/mapper/decrypted-$vg-userdata_a" $MOUNTP_USERDATA_A
    mount -t ext4 "/dev/mapper/decrypted-$vg-userdata_b" $MOUNTP_USERDATA_B

    cp -R $MOUNTP_USERDATA_PVSN/* $MOUNTP_USERDATA_A
    cp -R $MOUNTP_USERDATA_A/* $MOUNTP_USERDATA_B
    sync
    umount $MOUNTP_USERDATA_PVSN
    rm -rf $MOUNTP_USERDATA_PVSN

    # Secure erase logical volumes
    pvsn_wipe pvsn_rootfs
    pvsn_wipe pvsn_userdata
    sync

    # Remove provisioning volumes
    lvchange -an "/dev/mapper/$vg-pvsn_rootfs"
    lvchange -an "/dev/mapper/$vg-pvsn_userdata"
    lvremove --force --yes --verbose "/dev/mapper/$vg-pvsn_rootfs"
    lvremove --force --yes --verbose "/dev/mapper/$vg-pvsn_userdata"
    vgchange -a y
    vgmknodes

    # Close decrypted devices
    ${UMOUNT} $MOUNTP_USERDATA_A
    ${UMOUNT} $MOUNTP_USERDATA_B
    rm -rf $MOUNTP_USERDATA_A $MOUNTP_USERDATA_B

    dmsetup remove "/dev/mapper/decrypted-$vg-rootfs_a"
    dmsetup remove "/dev/mapper/decrypted-$vg-rootfs_b"
    dmsetup remove "/dev/mapper/decrypted-$vg-userdata_a"
    dmsetup remove "/dev/mapper/decrypted-$vg-userdata_b"
    dmsetup remove "/dev/mapper/decrypted-$vg-datastore"

    # Ensure key chain is clean
    keyctl unlink "$key_id" @us 2>/dev/null || keyctl revoke "$key_id" 2>/dev/null || true
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

mount_pseudo_fs

# we need udev to manage volumes cleanly
/sbin/udevd --daemon

echo "Populate LVM mapper devices"
vgchange -a y
vgmknodes

echo "Initramfs Bootstrap..."

parse_cmdline
echo "Root mnt     : ${ROOT_MNT}"
echo "Root device  : ${ROOT_DEV}"
echo "Crypt device : ${DECRYPT_ROOT_DEV}"
echo "Verity device: ${VERITY_DEV}"

if [ -n "${NFSPATH}" ]; then
    if ! ${MOUNT} -t nfs "${NFSPATH}" "${ROOT_MNT}"; then
        echo "ERROR: Failed to mount NFS root: ${NFSPATH}"
        exit 1
    fi
    if ! mount_device_data && ! mount_device_data_backup; then
        echo "ERROR: Continuing NFS boot without devicedata"
    fi
    echo "Switching root to Network File System"
else
    echo "Provisioning check..."
    if [ -e "/dev/mapper/matrixlvm-pvsn_rootfs" ]; then
        pvsn_flash
    fi

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
    if ! mount_runtime_volumes; then
        echo "ERROR: Mount runtime volumes failed"
        exit 1
    fi
    echo "Switching root to eMMC"
fi

udevadm settle
move_special_devices
exec switch_root "${ROOT_MNT}" "${INIT}" "${CMDLINE}"
