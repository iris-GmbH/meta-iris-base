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
    ${MOUNT} -t devtmpfs none /dev
    ${MOUNT} -t tmpfs tmp /tmp
    ${MOUNT} -t tmpfs tmp /run
    ${MOUNT} -t proc proc /proc
    ${MOUNT} -t sysfs sysfs /sys
    ${MOUNT} -t tmpfs tmpfs /var/volatile
    mkdir -p /var/volatile/log
    debug "Mount pseudo fs"
}

move_special_devices() {    
    ${MOUNT} --move /dev ${ROOT_MNT}/dev
    ${MOUNT} --move /proc ${ROOT_MNT}/proc
    ${MOUNT} --move /sys ${ROOT_MNT}/sys
    ${MOUNT} --move /var/volatile ${ROOT_MNT}/var/volatile
}

debug() {
    echo "$(date): ${*}" | tee -a "/var/volatile/log/initramfs.log"
}

parse_cmdline() {
    #Parse kernel cmdline to extract base device path
    CMDLINE="$(cat /proc/cmdline)"
    debug "Kernel cmdline: $CMDLINE"

    # Check if NFS boot is active
    if grep -q 'nfsroot' /proc/cmdline
    then
        NFSPATH=$(grep -Eo "nfsroot=[^ ]*" /proc/cmdline | tr '=' ',' | cut -d',' -f2)
    fi

    if grep -q 'linuxboot_b\|firmware_b' /proc/cmdline
    then
        FIRMWARE_SUFFIX="_b"
        ALT_FIRMWARE_SUFFIX="_a"
    else
        # default to firmware a
        FIRMWARE_SUFFIX="_a"
        ALT_FIRMWARE_SUFFIX="_b"
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
    debug "Initramfs provisioning flash routine started..."
    ROOT_DEV="/dev/mapper/irma6lvm-pvsn_rootfs"

    # Mount keystore
    KEYSTORE_DEV="/dev/mapper/irma6lvm-keystore"
    KEYSTORE="/mnt/keystore"
    ${MOUNT} ${KEYSTORE_DEV} ${KEYSTORE}

    # Generate black key blobs
    caam-keygen create volumeKey ccm -s 32

    # create userdata A/B mirrors
    if lvdisplay /dev/irma6lvm/userdata > /dev/null 2>&1; then
        # rename old partition to A/B format to support retrocompatibility
        lvrename -y -A n /dev/irma6lvm/userdata userdata_a
    fi
    vgmknodes

    # resize userdata_a to support retrocompatibility
    cur_size=$(lvs --select "lv_name = userdata_a" -o LV_SIZE --units m --nosuffix --noheadings | sed 's/  \([0-9]*\).*/\1/')
    req_size=256 # mb
    if [ "$cur_size" -gt "$req_size" ]; then
        debug "Resize userdata_a to $req_size M"
        e2fsck -f -p /dev/mapper/decrypted-irma6lvm-userdata_a
        resize2fs "/dev/mapper/decrypted-irma6lvm-userdata_a" "$req_size"M
        lvresize --autobackup n --force --yes --quiet -L "$req_size"M "/dev/mapper/irma6lvm-userdata_a"
    fi
    lvcreate --yes -n userdata_b -L 256MB irma6lvm
    lvcreate --yes -n datastore -L 512MB irma6lvm
    vgmknodes

    # Setup encrypted partitions
    keyctl padd logon logkey: @us < /mnt/keystore/caam/volumeKey
    dmsetup create decrypted-irma6lvm-rootfs_a --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-rootfs_a) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-rootfs_a 0 1 sector_size:4096"
    dmsetup create decrypted-irma6lvm-rootfs_b --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-rootfs_b) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-rootfs_b 0 1 sector_size:4096"
    dmsetup create decrypted-irma6lvm-userdata_a --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-userdata_a) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-userdata_a 0 1 sector_size:4096"
    dmsetup create decrypted-irma6lvm-userdata_b --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-userdata_b) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-userdata_b 0 1 sector_size:4096"
    dmsetup create decrypted-irma6lvm-datastore --table "0 $(blockdev --getsz /dev/mapper/irma6lvm-datastore) crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-datastore 0 1 sector_size:4096"
    vgmknodes

    # Copy rootfs
    dd if=/dev/mapper/irma6lvm-pvsn_rootfs of=/dev/mapper/decrypted-irma6lvm-rootfs_a
    dd if=/dev/mapper/irma6lvm-rootfs_a of=/dev/mapper/irma6lvm-rootfs_b
    sync

    # Mount and copy userdata A/B
    MOUNTP_USERDATA_A="/mnt/userdata_a"
    MOUNTP_USERDATA_B="/mnt/userdata_b"
    MOUNTP_USERDATA_PVSN="/mnt/pvsn_userdata"
    mkfs.ext4 /dev/mapper/decrypted-irma6lvm-userdata_a
    mkfs.ext4 /dev/mapper/decrypted-irma6lvm-userdata_b
    mkfs.ext4 /dev/mapper/decrypted-irma6lvm-datastore
    mkdir -p $MOUNTP_USERDATA_PVSN
    mkdir -p $MOUNTP_USERDATA_A
    mkdir -p $MOUNTP_USERDATA_B

    mount -t ext4 /dev/mapper/irma6lvm-pvsn_userdata $MOUNTP_USERDATA_PVSN
    mount -t ext4 /dev/mapper/decrypted-irma6lvm-userdata_a $MOUNTP_USERDATA_A
    mount -t ext4 /dev/mapper/decrypted-irma6lvm-userdata_b $MOUNTP_USERDATA_B

    mkdir -p $MOUNTP_USERDATA_A/counter
    mkdir -p $MOUNTP_USERDATA_A/irma6webserver
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
    lvchange -an "/dev/mapper/irma6lvm-pvsn_rootfs"
    lvchange -an "/dev/mapper/irma6lvm-pvsn_userdata"
    lvremove --force --yes --verbose "/dev/mapper/irma6lvm-pvsn_rootfs"
    lvremove --force --yes --verbose "/dev/mapper/irma6lvm-pvsn_userdata"
    vgchange -a y
    vgmknodes

    # Close decrypted devices
    umount $MOUNTP_USERDATA_A
    umount $MOUNTP_USERDATA_B
    dmsetup remove /dev/mapper/decrypted-irma6lvm-rootfs_a
    dmsetup remove /dev/mapper/decrypted-irma6lvm-rootfs_b
    dmsetup remove /dev/mapper/decrypted-irma6lvm-userdata_a
    dmsetup remove /dev/mapper/decrypted-irma6lvm-userdata_b
    dmsetup remove /dev/mapper/decrypted-irma6lvm-datastore

    # delete static data, if old pvsn_flash_deploy script was used
    if lvs "/dev/irma6lvm/staticdata" ; then
        lvremove -A n -q -y "/dev/irma6lvm/staticdata_hash"
        lvremove -A n -q -y "/dev/irma6lvm/staticdata"
    fi
}

emergency_switch() {
    pending_update=$(/usr/bin/fw_printenv upgrade_available | awk -F'=' '{print $2}')
    if [ "$pending_update" = "1" ]; then
        debug "Update pending, let bootcount switch firmware..."; exit 1;
    fi

    firmware=$(/usr/bin/fw_printenv firmware | awk -F'=' '{print $2}')
    if [ "$firmware" -eq 1 ] || [ "$firmware" -eq 0 ]; then
        new_firmware=$(( firmware^1 ))
        /usr/bin/fw_setenv firmware "$new_firmware"
        debug "Error: Emergency firmware switch from $firmware to $new_firmware"

        ${MOUNT} "/dev/mapper/${DECRYPT_DATASTORE_NAME}" "/mnt/datastore"
        mkdir -p "/mnt/datastore/log"
        cat /var/volatile/log/initramfs.log >> /mnt/datastore/log/initramfs.log
        ${UMOUNT} "/mnt/datastore"
        sync
    fi
    exit 1
}

lvm_volume_exists() {
    lvs "/dev/irma6lvm/$1" > /dev/null 2>&1
    return $?
}

try_create_userdata_mirror(){
    if ! lvm_volume_exists "userdata${FIRMWARE_SUFFIX}"; then
        debug "Create userdata${FIRMWARE_SUFFIX}"
        lvcreate -y --autobackup n -n "userdata${FIRMWARE_SUFFIX}" -L 256MB irma6lvm
        vgchange -a y
    fi
    dmsetup create ${DECRYPT_USERDATA_NAME} --table "0 $(blockdev --getsz ${USERDATA_DEV}) \
        crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${USERDATA_DEV} 0 1 sector_size:4096"
    vgmknodes

    # format current useradata if it is new
    if ! blkid /dev/mapper/${DECRYPT_USERDATA_NAME} | grep -q 'TYPE="ext4"'; then
        mkfs.ext4 -F /dev/mapper/${DECRYPT_USERDATA_NAME}
        sleep 1 # workaround for removing without busy errors
    fi

    dmsetup remove ${DECRYPT_USERDATA_NAME}
}

try_remove_staticdata(){
    if lvm_volume_exists "staticdata" > /dev/null 2>&1; then
        lvremove -A n -q -y "/dev/irma6lvm/staticdata_hash" > /dev/null 2>&1
        lvremove -A n -q -y "/dev/irma6lvm/staticdata" > /dev/null 2>&1
    fi
}

# sync_userdata_from_alt
# try to sync config from alternative userdata
# will exit 1 if failed
sync_userdata_from_alt(){
    err=0
    # compatibility hack for old lvm layout with single userdata (fw =< 3.0.0)
    # can removed on major version 5
    ALT_USERDATA_FIRMWARE_SUFFIX=${ALT_FIRMWARE_SUFFIX}
    if lvm_volume_exists "userdata"; then
        ALT_USERDATA_FIRMWARE_SUFFIX=""
    fi

    # decrypt existing userdata A/B
    dmsetup create ${DECRYPT_USERDATA_NAME} --table "0 $(blockdev --getsz ${USERDATA_DEV}) \
        crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${USERDATA_DEV} 0 1 sector_size:4096"

    dmsetup create ${ALT_DECRYPT_USERDATA_NAME} --table \
        "0 $(blockdev --getsz /dev/mapper/irma6lvm-userdata${ALT_USERDATA_FIRMWARE_SUFFIX}) \
        crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 /dev/mapper/irma6lvm-userdata${ALT_USERDATA_FIRMWARE_SUFFIX} 0 1 sector_size:4096"
    vgmknodes

    # mount userdata A/B
    mkdir -p /tmp/userdata${FIRMWARE_SUFFIX}
    mkdir -p /tmp/userdata${ALT_FIRMWARE_SUFFIX}
    mount -t ext4 /dev/mapper/${DECRYPT_USERDATA_NAME} /tmp/userdata${FIRMWARE_SUFFIX} || err=1
    mount -t ext4 /dev/mapper/${ALT_DECRYPT_USERDATA_NAME} /tmp/userdata${ALT_FIRMWARE_SUFFIX} || err=1
    [ "$err" -eq 0 ] || exit "$err"

    # sync alternative -> current
    # use persitent flag to sync only once
    SYNC_FILE="/tmp/userdata${FIRMWARE_SUFFIX}/userdata_synced"
    if [ ! -f $SYNC_FILE ]; then
        debug "Sync Userdata: ${ALT_FIRMWARE_SUFFIX} to ${FIRMWARE_SUFFIX}"
        rsync -a --delete /tmp/userdata${ALT_FIRMWARE_SUFFIX}/ /tmp/userdata${FIRMWARE_SUFFIX} || err=1
        [ "$err" -eq 0 ] || exit "$err"
    fi
    touch $SYNC_FILE # sync file is removed on power on test
    sync

    # clean up
    umount /tmp/userdata${FIRMWARE_SUFFIX}
    umount /tmp/userdata${ALT_FIRMWARE_SUFFIX}
    rm -rf /tmp/userdata${FIRMWARE_SUFFIX}
    rm -rf /tmp/userdata${ALT_FIRMWARE_SUFFIX}
    dmsetup remove ${DECRYPT_USERDATA_NAME}
    dmsetup remove ${ALT_DECRYPT_USERDATA_NAME}
}

try_create_datastore(){
    if ! lvs ${DATASTORE_DEV} > /dev/null 2>&1; then
        debug "Creating Datastore Volume..."
        lvcreate -y --autobackup n -n "${DATASTORE_NAME}" -L 512MB irma6lvm
        vgchange -a y
    fi

    dmsetup create ${DECRYPT_DATASTORE_NAME} --table "0 $(blockdev --getsz ${DATASTORE_DEV}) \
        crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${DATASTORE_DEV} 0 1 sector_size:4096"
    vgmknodes

    # format datastore
    if ! blkid /dev/mapper/${DECRYPT_DATASTORE_NAME} | grep -q 'TYPE="ext4"'; then
        mkfs.ext4 -F /dev/mapper/${DECRYPT_DATASTORE_NAME}
        sleep 1 # workaround for removing without busy errors
    fi
    dmsetup remove ${DECRYPT_DATASTORE_NAME}
}

mount_pseudo_fs

# populate LVM mapper devices
vgchange -a y
vgmknodes

debug "Initramfs Bootstrap..."
parse_cmdline

# If NFS is active, switchroot now
if [ -n "${NFSPATH}" ]
then
    ${MOUNT} -t nfs "${NFSPATH}" ${ROOT_MNT}
    debug "Switching root to Network File System"
    move_special_devices
    exec switch_root ${ROOT_MNT} "${INIT}" "${CMDLINE}"
    exit 0
fi

/etc/init.d/udev start # we need udev to manage volumes cleanly

# check if we are in provisioning and need to encrypt the volumes
debug "Provisioning check..."
if [ -e "/dev/mapper/irma6lvm-pvsn_rootfs" ]; then
    pvsn_flash
fi


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

USERDATA_DEV="/dev/mapper/irma6lvm-userdata${FIRMWARE_SUFFIX}"
DECRYPT_USERDATA_NAME="decrypted-irma6lvm-userdata${FIRMWARE_SUFFIX}"
DECRYPT_USERDATA_LINK="/dev/mapper/decrypted-irma6lvm-userdata"
ALT_DECRYPT_USERDATA_NAME="decrypted-irma6lvm-userdata${ALT_FIRMWARE_SUFFIX}"

DATASTORE_NAME="datastore"
DATASTORE_DEV="/dev/mapper/irma6lvm-datastore"
DECRYPT_DATASTORE_NAME="decrypted-irma6lvm-datastore"

PUBKEY="/etc/iris/signing/roothash-public-key.pem"

debug "Select firmware${FIRMWARE_SUFFIX}"

# Check root device
debug "Root mnt   : ${ROOT_MNT}"
debug "Root device: ${ROOT_DEV}"
debug "Crypt device: ${DECRYPT_ROOT_DEV}"
debug "Verity device: ${VERITY_DEV}"

${MOUNT} ${KEYSTORE_DEV} ${KEYSTORE}

# Add Black key to keyring
caam-keygen import $KEYSTORE/caam/volumeKey.bb volumeKey
keyctl padd logon logkey: @us < $KEYSTORE/caam/volumeKey

PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
if [ "$PENDING_UPDATE" = "1" ]; then
    # power fail safe operations

    # adjust lvm layout: can be removed on major release 5
    try_create_userdata_mirror

    # get config from alternative userdata on update
    sync_userdata_from_alt

    # adjust lvm layout: can be removed on major release 5
    try_create_datastore

    # adjust lvm layout: can be removed on major release 5
    try_remove_staticdata
fi

debug "Unlocking encrypted device: ${ROOT_DEV}" 
dmsetup create ${DECRYPT_NAME} --table "0 $(blockdev --getsz ${ROOT_DEV}) \
    crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${ROOT_DEV} 0 1 sector_size:4096"

debug "Unlocking encrypted device: ${USERDATA_DEV}"
dmsetup create ${DECRYPT_USERDATA_NAME} --table "0 $(blockdev --getsz ${USERDATA_DEV}) \
    crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${USERDATA_DEV} 0 1 sector_size:4096"

debug "Unlocking encrypted device: ${DATASTORE_DEV}"
dmsetup create ${DECRYPT_DATASTORE_NAME} --table "0 $(blockdev --getsz ${DATASTORE_DEV}) \
    crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${DATASTORE_DEV} 0 1 sector_size:4096"
vgmknodes

ln -s "/dev/mapper/${DECRYPT_USERDATA_NAME}" "${DECRYPT_USERDATA_LINK}" # symlink for /etc/fstab

if ! /usr/bin/openssl dgst -sha256 -verify "${PUBKEY}" -signature "${ROOT_HASH_SIGNATURE}" "${ROOT_HASH}"
then
    debug "Root hash signature invalid"
    emergency_switch
fi
RH=$(cat "${ROOT_HASH}")

${UMOUNT} ${KEYSTORE}

debug "Opening verity device: ${DECRYPT_ROOT_DEV}"
veritysetup open ${DECRYPT_ROOT_DEV} ${VERITY_NAME} ${ROOT_HASH_DEV} "${RH}"

if ! ${MOUNT} ${VERITY_DEV} ${ROOT_MNT} -o ro 
then
    debug "Mount root device failed"
    emergency_switch
fi
debug "Switching root to verity device"
move_special_devices
exec switch_root ${ROOT_MNT} "${INIT}" "${CMDLINE}"
