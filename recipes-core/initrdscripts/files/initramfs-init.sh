#!/bin/sh
#
# open rootfs from lvm
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

ROOT_MNT="/mnt"

# mount/umount
MOUNT="/bin/mount"
UMOUNT="/bin/umount"

MOUNT_OPT="-o ro"

# init
if [ -z ${INIT} ];then
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
    if [ "${DEBUGSHELL}" == "yes" ]; then
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
    echo "ERROR: ${@}" > /dev/console
    debug_reboot
}

error() {
    echo "Error: ${@}"
}

debug() {
    echo "${@}"
}

parse_cmdline() {
    #Parse kernel cmdline to extract base device path
    CMDLINE="$(cat /proc/cmdline)"
    debug "Kernel cmdline: $CMDLINE"

    grep enablelog /proc/cmdline > /dev/null
    if [ $? -eq 0 ]; then
        ENABLELOG="yes"
    fi
    grep debugshell /proc/cmdline > /dev/null
    if [ $? -eq 0 ]; then
        DEBUGSHELL="yes"
    fi
    grep enterinitramfs /proc/cmdline > /dev/null
    if [ $? -eq 0 ]; then
        ENTERINITRAMFS="yes"
    fi
    grep -q 'boot_type=factory' /proc/cmdline
    if [ $? -eq 0 ]; then
        FACTORYSETUP="yes"
    fi
    grep -q 'linuxboot_b\|firmware_b' /proc/cmdline
    if [ $? -eq 0 ]; then
        FIRMWARE_SUFFIX="_b"
    else
    # default to firmware a
        FIRMWARE_SUFFIX="_a"
    fi
}

mount_pseudo_fs

# populate LVM mapper devices
vgchange -a y
vgmknodes

echo "Initramfs Bootstrap..."
parse_cmdline

ROOT_DEV="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}"
ROOT_HASH="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}_hash"

KEYSTORE_DEV="/dev/mapper/irma6lvm-keystore"
KEYSTORE="/tmp/keystore"

VERITY_NAME="verity-rootfs${FIRMWARE_SUFFIX}"
VERITY_DEV="/dev/mapper/${VERITY_NAME}"

DECRYPT_NAME="decrypted-irma6lvm-rootfs${FIRMWARE_SUFFIX}"
DECRYPT_ROOT_DEV="/dev/mapper/${DECRYPT_NAME}"

DATA_DEV="/dev/mapper/irma6lvm-userdata"
DECRYPT_DATA_NAME="decrypted-irma6lvm-userdata"


debug "Select firmware${FIRMWARE_SUFFIX}"

if [ "${FACTORYSETUP}" == "yes" ]; then
    if [ -f  /etc/functions_factory ]; then
	. /etc/functions_factory
	factory_setup
	debug_reboot
    fi
fi

# Check root device
debug "Root mnt   : ${ROOT_MNT}"
debug "Root device: ${ROOT_DEV}"
debug "Crypt device: ${DECRYPT_ROOT_DEV}"
debug "Verity device: ${VERITY_DEV}"

if [ "${ROOT_DEV}" == "" ] || [ "${ROOT_DEV}" == "/dev/nfs" ]; then
    error_exit
fi

mkdir ${KEYSTORE}
mount ${KEYSTORE_DEV} ${KEYSTORE}
RH=$(cat "${KEYSTORE}/rootfs${FIRMWARE_SUFFIX}_roothash")

# Add Black key to keyring
ln -s $KEYSTORE /data
caam-keygen import $KEYSTORE/caam/volumeKey.bb importKey
cat $KEYSTORE/caam/importKey | keyctl padd logon logkey: @us
rm /data

debug "Unlocking encrypted device: ${ROOT_DEV}" 
dmsetup create ${DECRYPT_NAME} --table "0 $(blockdev --getsz ${ROOT_DEV}) \
    crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${ROOT_DEV} 0 1 sector_size:4096"

debug "Unlocking encrypted device: ${DATA_DEV}"
dmsetup create ${DECRYPT_DATA_NAME} --table "0 $(blockdev --getsz ${DATA_DEV}) \
    crypt capi:tk(cbc(aes))-plain :64:logon:logkey: 0 ${DATA_DEV} 0 1 sector_size:4096"
vgmknodes

debug "Opening verity device: ${DECRYPT_ROOT_DEV}"
veritysetup open ${DECRYPT_ROOT_DEV} ${VERITY_NAME} ${ROOT_HASH} ${RH}

mount ${VERITY_DEV} ${ROOT_MNT} ${MOUNT_OPT}

umount ${KEYSTORE}

#Switch to real root
echo "Switch to root"
exec switch_root ${ROOT_MNT} ${INIT} ${CMDLINE}
