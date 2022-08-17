#!/bin/sh
#
# open rootfs from lvm
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

ROOT_MNT="/mnt"

MOUNT="/bin/mount"
UMOUNT="/bin/umount"

# init
if [ -z "${INIT}" ];then
    INIT=/sbin/init
fi

mount_pseudo_fs() {
    debug "Mount pseudo fs"
    ${MOUNT} -t devtmpfs none /dev
    ${MOUNT} -t tmpfs tmp /tmp
    ${MOUNT} -t tmpfs tmp /run
    ${MOUNT} -t proc proc /proc
    ${MOUNT} -t sysfs sysfs /sys
}

debug_reboot() {
    if [ "${DEBUGSHELL}" = "yes" ]; then
        echo "enter debugshell"
        /bin/sh
    else
        # wait 5 seconds then reboot
        echo "Reboot in 5 seconds..." > /dev/console
        sleep 5
        reboot -f
    fi
}

error_exit() {
    echo "ERROR: ${*}" > /dev/console
    debug_reboot
}

error() {
    echo "Error: ${*}"
}

debug() {
    echo "${@}"
}

parse_cmdline() {
    #Parse kernel cmdline to extract base device path
    CMDLINE="$(cat /proc/cmdline)"
    debug "Kernel cmdline: $CMDLINE"

    if grep -q debugshell /proc/cmdline
    then
        DEBUGSHELL="yes"
    fi
    if grep -q 'linuxboot_b\|firmware_b' /proc/cmdline
    then
        FIRMWARE_SUFFIX="_b"
    else
        # default to firmware a
        FIRMWARE_SUFFIX="_a"
    fi
}

pvsn_wipe() {
    sector_size=512 # 512 bytes
    first_pe=2048 # first physical extent starts at 1 MiB (2048 sectors * 512B sector size) (LVM MDA is located here)
    partition_offset=$(cat "/sys/class/block/mmcblk2p5/start")
    pv_size=$(pvs --no-heading --no-suffix -o pv_size --unit B | xargs) # physical volume size in bytes
    pe_count=$(pvs --no-heading -o pv_pe_count | xargs) # physical extent count
    pe_size=$((pv_size / pe_count)) # physical extent size in bytes (should be 4 MiB)
    lv_start_pe=$(pvs --no-headings -o seg_pe_ranges --select "lv_name = $1" | sed -e 's/.*:\(.*\)-.*/\1/') # start of logical volume in physical extents
    lv_size_pe=$(pvs --no-headings -o seg_size_pe --select "lv_name = $1" | xargs) # size of logical volume in physical extents

    # convert bytes to mmc sectors (512B per sector)
    start=$((lv_start_pe * pe_size / sector_size + partition_offset + first_pe))
    end=$(((lv_start_pe + lv_size_pe) * pe_size / sector_size + partition_offset + first_pe - 1))

    mmc erase secure-erase "$start" "$end" "/dev/mmcblk2"
}

# provisioning flash procedure
pvsn_flash() {
    echo "Initramfs provisioning flash routine started..."
    ROOT_DEV="/dev/mapper/irma6lvm-pvsn_rootfs"
    DATA_DEV="/dev/mapper/irma6lvm-pvsn_userdata"

    # Mount keystore
    KEYSTORE_DEV="/dev/mapper/irma6lvm-keystore"
    KEYSTORE="/mnt/keystore"
    ${MOUNT} ${KEYSTORE_DEV} ${KEYSTORE}

    # Generate black key blobs
    caam-keygen create volumeKey ccm -s 32

    # Setup encrypted partitions
    keyctl padd logon logkey: @us < /mnt/keystore/caam/volumeKey
    dmsetup -v create decrypted-irma6lvm-rootfs_a --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-rootfs_a) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-rootfs_a 0 1 sector_size:4096"
    dmsetup -v create decrypted-irma6lvm-rootfs_b --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-rootfs_b) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-rootfs_b 0 1 sector_size:4096"
    dmsetup -v create decrypted-irma6lvm-userdata --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-userdata) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-userdata 0 1 sector_size:4096"
    vgmknodes

    # Copy rootfs
    dd if=/dev/mapper/irma6lvm-pvsn_rootfs of=/dev/mapper/decrypted-irma6lvm-rootfs_a
    dd if=/dev/mapper/irma6lvm-rootfs_a of=/dev/mapper/irma6lvm-rootfs_b
    sync

    # Mount and copy userdata
    mkfs.ext4 /dev/mapper/decrypted-irma6lvm-userdata
    mkdir -p /mnt/pvsn_userdata
    mkdir -p /mnt/userdata
    mount -t ext4 /dev/mapper/decrypted-irma6lvm-userdata /mnt/userdata
    mount -t ext4 /dev/mapper/irma6lvm-pvsn_userdata /mnt/pvsn_userdata
    mkdir -p /mnt/userdata/counter
    cp -R /mnt/pvsn_userdata/* /mnt/userdata
    umount /mnt/userdata
    umount /mnt/pvsn_userdata
    rm -R /mnt/pvsn_userdata
    rm -R /mnt/userdata
    sync

    # Secure erase logical volumes
    pvsn_wipe pvsn_rootfs
    pvsn_wipe pvsn_userdata
    sync
    
    # Remove provisioning volumes
    lvchange -an "/dev/mapper/irma6lvm-pvsn_rootfs"
    lvchange -an "/dev/mapper/irma6lvm-pvsn_userdata"
    lvremove --force --yes --verbose "/dev/mapper/irma6lvm-pvsn_rootfs"
    lvremove --force --yes --verbose "/dev/mapper/irma6lvm-pvsn_userdata"
    vgchange -a y
    vgmknodes

    # Close decrypted devices
    dmsetup remove /dev/mapper/decrypted-irma6lvm-rootfs_a
    dmsetup remove /dev/mapper/decrypted-irma6lvm-rootfs_b
    dmsetup remove /dev/mapper/decrypted-irma6lvm-userdata
}

mount_pseudo_fs

# populate LVM mapper devices
vgchange -a y
vgmknodes

# check if we are in provisioning and need to encrypt the volumes
echo "Provisioning check..."
if [ -e "/dev/mapper/irma6lvm-pvsn_rootfs" ]; then
    pvsn_flash
fi

echo "Initramfs Bootstrap..."
parse_cmdline

KEYSTORE_DEV="/dev/mapper/irma6lvm-keystore"
KEYSTORE="/mnt/keystore"

ROOT_DEV=/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}
ROOT_HASH_DEV=/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}_hash
ROOT_HASH=${KEYSTORE}/rootfs${FIRMWARE_SUFFIX}_roothash
ROOT_HASH_SIGNATURE=${KEYSTORE}/rootfs${FIRMWARE_SUFFIX}_roothash.signature

VERITY_NAME="verity-rootfs${FIRMWARE_SUFFIX}"
VERITY_DEV="/dev/mapper/${VERITY_NAME}"

DECRYPT_NAME="decrypted-irma6lvm-rootfs${FIRMWARE_SUFFIX}"
DECRYPT_ROOT_DEV="/dev/mapper/${DECRYPT_NAME}"

DATA_DEV="/dev/mapper/irma6lvm-userdata"
DECRYPT_DATA_NAME="decrypted-irma6lvm-userdata"

PUBKEY="/etc/iris/signing/roothash-public-key.pem"

debug "Select firmware${FIRMWARE_SUFFIX}"

# Check root device
debug "Root mnt   : ${ROOT_MNT}"
debug "Root device: ${ROOT_DEV}"
debug "Crypt device: ${DECRYPT_ROOT_DEV}"
debug "Verity device: ${VERITY_DEV}"

${MOUNT} ${KEYSTORE_DEV} ${KEYSTORE}

if ! /usr/bin/openssl dgst -sha256 -verify "${PUBKEY}" -signature "${ROOT_HASH_SIGNATURE}" "${ROOT_HASH}"
then
    exit 1
fi
RH=$(cat "${ROOT_HASH}")

# Add Black key to keyring
caam-keygen import $KEYSTORE/caam/volumeKey.bb importKey
keyctl padd logon logkey: @us < $KEYSTORE/caam/importKey

debug "Unlocking encrypted device: ${ROOT_DEV}" 
dmsetup create ${DECRYPT_NAME} --table "0 $(blockdev --getsz ${ROOT_DEV}) \
    crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${ROOT_DEV} 0 1 sector_size:4096"

debug "Unlocking encrypted device: ${DATA_DEV}"
dmsetup create ${DECRYPT_DATA_NAME} --table "0 $(blockdev --getsz ${DATA_DEV}) \
    crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${DATA_DEV} 0 1 sector_size:4096"
vgmknodes

${UMOUNT} ${KEYSTORE}

debug "Opening verity device: ${DECRYPT_ROOT_DEV}"
veritysetup open ${DECRYPT_ROOT_DEV} ${VERITY_NAME} ${ROOT_HASH_DEV} ${RH}

${MOUNT} ${VERITY_DEV} ${ROOT_MNT} -o ro

#Switch to real root
echo "Switch to root"
exec switch_root ${ROOT_MNT} ${INIT} "${CMDLINE}"
