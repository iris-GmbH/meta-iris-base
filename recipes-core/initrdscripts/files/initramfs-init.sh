#!/bin/sh
#
# open rootfs from lvm
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

ROOT_MNT="/mnt"

# mount/umount
MOUNT="/bin/mount"
UMOUNT="/bin/umount"

# TODO: Dynamically switch a/b. Could be done via a kernel parameter - see parse_cmdline()
ROOT_DEV="/dev/mapper/irma6lvm-rootfs_a"

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

    # Only extract ROOT_DEV when it is not set previously
    if [ ! -n ${ROOT_DEV} ]; then
	for c in ${CMDLINE}; do
	    if [ "${c:0:5}" == "root=" ]; then
		ROOT_DEV="${c:5}"
	    fi
	done
    fi
    debug "ROOT_DEV $ROOT_DEV"

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
}

mount_pseudo_fs

# populate LVM mapper devices
vgchange -a y
vgmknodes

echo "Initramfs Bootstrap..."
parse_cmdline

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

if [ "${ROOT_DEV}" == "" ] || [ "${ROOT_DEV}" == "/dev/nfs" ]; then
    error_exit
fi

mount ${ROOT_DEV} ${ROOT_MNT}

#Switch to real root
echo "Switch to root"
exec switch_root ${ROOT_MNT} ${INIT} ${CMDLINE}
