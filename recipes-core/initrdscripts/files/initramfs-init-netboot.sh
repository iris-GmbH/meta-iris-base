#!/bin/sh
#
# open rootfs from lvm
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

ROOT_MNT="/mnt"

MOUNT="/bin/mount"

# init
if [ -z "${INIT}" ];then
    INIT=/sbin/init
fi

mount_pseudo_fs() {
    debug "Mount pseudo fs"
    ${MOUNT} -t devtmpfs none /dev
    ${MOUNT} -t tmpfs tmp /tmp
    ${MOUNT} -t proc proc /proc
    ${MOUNT} -t sysfs sysfs /sys
}

debug() {
    echo "${@}"
}

parse_cmdline() {
    #Parse kernel cmdline to extract base device path
    CMDLINE="$(cat /proc/cmdline)"
    debug "Kernel cmdline: $CMDLINE"
    if grep -q 'nfsroot' /proc/cmdline
    then
        NFSPATH=$(grep -Eo "nfsroot=[^ ]*" /proc/cmdline | tr '=' ',' | cut -d',' -f2)
    fi
}

mount_pseudo_fs

# populate LVM mapper devices
vgchange -a y
vgmknodes

echo "Initramfs Bootstrap..."
parse_cmdline

echo; echo; echo
echo "####################################################"
echo "####################################################"
echo "##! INITRAMFS FOR NETBOOT - ONLY FOR DEVELOPMENT !##"
echo "####################################################"
echo "####################################################"
echo; echo; echo

${MOUNT} -t nfs "${NFSPATH}" ${ROOT_MNT}
${MOUNT} --move /dev ${ROOT_MNT}/dev
${MOUNT} --move /proc ${ROOT_MNT}/proc
${MOUNT} --move /sys ${ROOT_MNT}/sys

#Switch to real root
echo "Switch to root"
exec switch_root ${ROOT_MNT} ${INIT}
