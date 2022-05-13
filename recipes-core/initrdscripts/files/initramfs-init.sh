#!/bin/sh
#
# check if rootfs is signed correct and if so encrypt it
#
# start preinit

#set -x
PATH=/sbin:/bin:/usr/sbin:/usr/bin

MB=$((1024*1024))
MAGIC="0x44454e585f4d4743" # DENX_MGC
MAGIC_LEN=8
MAGIC_SIZE="4096"
BIN_SIG=/tmp/bin.sig
BIN_DIGEST=/tmp/bin.digest
ROOT_MNT="/mnt"
ROOT_OPT="-o ro"

# mount/umount
MOUNT="/bin/mount"
UMOUNT="/bin/umount"

#include functions
. /etc/default/initramfs

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

umount_pseudo_fs() {
    debug "Umount pseudo fs"
    ${UMOUNT} /dev
    ${UMOUNT} /tmp
    ${UMOUNT} /proc
    ${UMOUNT} /sys
}

detect_imx_crypto_engine() {
    crypt_acc="caam"
    # detect if CAAM or DCP is the engine
    cat /proc/crypto | grep -i dcp >/dev/null
    if [ $? == 0 ];then
	crypt_acc="dcp"
    fi
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
    logger -t error -s "${@}"
}

debug() {
    if [ "$VERBOSE" != "no" ]; then
	echo "${@}"
    else
	if [ "$ENABLELOG" != "no" ]; then
	    logger -s "${@}"
	fi
    fi
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


find_magic_offset() {
    if [ -z  ${MAGIC_OFFSET} ];then
	MAGIC_OFFSET=0
    fi
    if [ -z ${MAX_SIZE} ];then
	MAX_SIZE="$(lsblk -b -n $1 | awk '{print $4}')"
    fi
    while [ ${MAGIC_OFFSET} -lt ${MAX_SIZE} ]; do
	var="$(hexdump -e '"0x" 8/1 "%02x"' ${1} -s ${MAGIC_OFFSET} -n ${MAGIC_LEN})"
	if [[ "${var}" == "${MAGIC}" ]]; then
	    debug "magic offset found @ ${MAGIC_OFFSET}"
	    break
	fi
	let "MAGIC_OFFSET += ${MB}"
    done
    if [[ "${MAGIC_OFFSET}" == "${MAX_SIZE}" ]]; then
	echo "no magic offset found!"
	error_exit
    fi
}

calc_digest() {
    (
	dd if=${1} bs=1M count=$(expr ${MAGIC_OFFSET} / ${MB}) | openssl dgst -sha256 -binary -out ${BIN_DIGEST}
    ) > /dev/null 2>&1
}

extract_signature() {
    SIGNATURE=/tmp/$(basename ${1}.sig)
    # Signature is one 4k block further than magic offset
    SIGNATURE_OFFSET="$(expr $(expr ${MAGIC_OFFSET} / 4096) + 1)"
    dd if=${1} of=${SIGNATURE} bs=4k skip=${SIGNATURE_OFFSET} count=1 > /dev/null 2>&1
}

verify_signature() {
    base64 -d ${SIGNATURE} > ${BIN_SIG}
    openssl pkeyutl -verify -in ${BIN_DIGEST} -pubin -inkey ${PUB_KEY} -sigfile ${BIN_SIG} -pkeyopt digest:sha256 || error_exit
    rm -f ${SIGNATURE} ${BIN_SIG} ${BIN_DIGEST}
}

# $1: offset
check_key() {
    key_found=0
    # check if key is stored
    # Only 64B are read and the check is done against 0x00 or 0xFF
    if [ "${keystoredev}" == "spi" ]; then
	mtd_debug read $storedevice $1 40 /tmp/keytmp > /dev/null
    elif [ "${keystoredev}" == "mmc" ]; then
	dd if=/dev/mmcblk${keystoremmcdev}${keystoremmcpart} of=/tmp/keytmp_tmp bs=512 skip=${1} count=1 2>/dev/null
	dd if=/tmp/keytmp_tmp of=/tmp/keytmp bs=1 count=40 2>/dev/null
    else
	dd if=${keyblobpath} of=/tmp/keytmp bs=1 count=40
    fi
    md5sum /tmp/keytmp > /tmp/keytmp2
    # md5sum of 0xff (SPI-NOR)
    grep 5c7191c0bf59f6d17bbe1bb4bf222e6b /tmp/keytmp2
    if [ $? -ne 0 ]; then
	# md5sum of 0x00 (eMMC) for 40 bytes
	grep fd4b38e94292e00251b9f39c47ee5710 /tmp/keytmp2
	[ $? -ne 0 ] && key_found=1
    fi

    rm /tmp/keytmp*
}

mount_pseudo_fs
detect_imx_crypto_engine

# This is a custom fuction that MUST be provided
load_key_blob
get_root_dev_path

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
debug "Root opt   : ${ROOT_OPT}"

if [ "${ROOT_DEV}" == "" ] || [ "${ROOT_DEV}" == "/dev/nfs" ]; then
    error_exit
fi

encrypt_rootfs () {
    debug "encrypt rootfs " $1

    if [ "${ENTERINITRAMFS}" == "yes" ];then
	echo "enter initramfs shell"
	/bin/sh
    fi

    if [ "${USEENCRYPTED}" == "no" ];then
	debug "rootfs not encrypted"
	mkdir -p ${ROOT_MNT}
	mount -t squashfs ${ROOT_OPT} $1 ${ROOT_MNT}
	return
    fi

    ## Load dm-crypt.ko, it will create a special keyring for our caam key
    insmod /lib/modules/$(uname -r)/kernel/drivers/md/dm-crypt.ko

    ## Load the blob into dcp/caam
    echo "LOAD keyblob no keyid"
    keyctl add symmetric "mydiskkey" "${crypt_acc} load_blob $(cat ${keyblobpath} | tr -d '\0')" @u
    echo "DONE ----------------------" $?
    keyctl show -x
    keyctl show -x @us

    ## Activate the DM-Crypt disk, $1 is the encrypted block device
    cryptsetup open -s 128 -c aes-cbc-essiv:sha256 --type plain --key-desc mydiskkey $1 cr_disk > /dev/null

    ## mount it
    mkdir -p ${ROOT_MNT}
    mount ${ROOT_OPT} /dev/mapper/cr_disk ${ROOT_MNT}

    if [ $? != 0 ];then
	echo "Error mounting rootfs"
	error_exit
    fi
}

wait_rootfs() {
    # wait endless for rootfs, as WDT triggers if rootfs
    # does not come up
    debug "wait for root fs:  ${ROOT_FS} ..."
    DEV=$(echo $1 | cut -d "/" -f 3)
    debug "DEV ${DEV}"

    BLKDEV=$(echo $DEV | cut -d "p" -f 1)
    PARTDEV=$(echo $DEV | cut -d "p" -f 2)
    debug "BLKDEV ${BLKDEV} partdev ${PARTDEV}"

    LOOP="notset"
    while [ $LOOP != "FOUND" ];do
	sleep 0.5
	LOOP=$(dmesg | grep $BLKDEV | grep p$PARTDEV | while IFS= read -r line ; do if echo $line | grep Kernel > /dev/null; then true; else echo "FOUND"; fi; done)
    done
}

# Only wait for rootfs to be up for SPI-NOR
if [ "${keystoredev}" == "spi" ]; then
    ROOT_FS=$(findfs ${ROOT_DEV})
    wait_rootfs ${ROOT_FS}
fi

if [ "x${VERIFYROOTFS}" == "xno" ];then
    echo "ROOTFS verification not required, skipping..."
else
    debug "Verifying root fs:  ${ROOT_FS} ..."
    find_magic_offset ${ROOT_FS}
    calc_digest ${ROOT_FS}
    extract_signature ${ROOT_FS}
    verify_signature ${ROOT_FS}
fi

encrypt_rootfs ${ROOT_DEV}

umount_pseudo_fs

#Switch to real root
echo "Switch to root"
exec switch_root ${ROOT_MNT} ${INIT} ${CMDLINE}
