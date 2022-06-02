ROOT_DEV="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}"
ROOT_HASH="/dev/mapper/irma6lvm-rootfs${FIRMWARE_SUFFIX}_hash"

VERITY_NAME="verity-rootfs${FIRMWARE_SUFFIX}"
VERITY_DEV="/dev/mapper/${VERITY_NAME}"

HASH_DEV="/dev/mapper/irma6lvm-keystore"
HASH_MNT="/tmp/keystore"

debug "Select ${FIRMWARE_SUFFIX}"

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
debug "Verity device: ${VERITY_DEV}"

if [ "${ROOT_DEV}" == "" ] || [ "${ROOT_DEV}" == "/dev/nfs" ]; then
    error_exit
fi

mkdir ${HASH_MNT}
mount ${HASH_DEV} ${HASH_MNT}
RH=$(cat "${HASH_MNT}/rootfs${FIRMWARE_SUFFIX}_roothash")
umount ${HASH_MNT}

veritysetup open ${ROOT_DEV} ${VERITY_NAME} ${ROOT_HASH} ${RH}
mount ${VERITY_DEV} ${ROOT_MNT} ${MOUNT_OPT}
