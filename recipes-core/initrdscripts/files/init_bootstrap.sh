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
    grep -q 'nfsroot' /proc/cmdline
    if [ $? -eq 0 ]; then
        NFSPATH=$(grep -Eo "nfsroot=[^ ]*" /proc/cmdline | tr '=' ',' | cut -d',' -f2)
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
