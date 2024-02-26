# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

inherit deploy

IMAGENAME ?= "${@ d.getVar('PN').replace('-uuu','')}"

### Parameters to set in the bb file that include this inc file ###
### bb file must also set: PARTITIONS and UUUSCRIPT
# use fitImages (in case of secure boot) for uuu/mfgtool and to flash, or handle kernel image, kernel dtb and initramfs (uuu only) seperately
USE_FITIMAGES ?= "1"

# use dmverity and root hash signatures, use ext4.gz as image type that gets flashed directly instead of unpacking a tar.gz
USE_ROOTFS_DMVERITY ?= "1"

# make use of a verification script, filepath needs to be set in VERIFICATIONSCRIPT, will provide hashes of artifacts
USE_VERIFICATION_SCRIPT ?= "1"

# Include SWUPDATE_AES_SNAKEOIL_FILE and IDENTITY_SNAKEOIL_* key material
DEPLOY_SNAKEOIL_KEYS ?= "1"

# Depend on image (read from PN), initrams, kernel and imx-boot (u-boot)
do_install[depends] = "\
    ${IMAGENAME}:do_image_complete \
    ${@bb.utils.contains('USE_FITIMAGES', '1', '${FITIMAGE_NAME}:do_assemble_fit', '', d)} \
    ${@bb.utils.contains('USE_FITIMAGES', '1', '${FITIMAGE_UUU_NAME}:do_assemble_fit', '', d)} \
    ${@bb.utils.contains('USE_FITIMAGES', '0', '${INITRAMFS_IMAGE}:do_image_complete', '', d)} \
    virtual/kernel:do_deploy"
DEPENDS = "imx-boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# skip tasks, as we only want to deploy things
do_configure[noexec] = "1"
do_install[noexec] = "1"
do_compile[noexec] = "1"
do_deploy[nostamp] = "1"

# Variables - must be set in bb file
INITRAMFS_IMAGE ?= ""
FITIMAGE_NAME ?= ""
FITIMAGE_UUU_NAME ?= ""

PARTITIONS ?= ""
UUUSCRIPT ?= ""
VERIFICATIONSCRIPT ?= ""

# Set file paths of source files
ROOTFS_EXT ?= "ext4.gz"
ROOTFS = "${IMAGENAME}-${MACHINE}.${ROOTFS_EXT}"
ROOTFSVERITY = "${IMAGENAME}-${MACHINE}.ext4.hashdevice"
ROOTFSROOTHASH = "${IMAGENAME}-${MACHINE}.ext4.roothash"
ROOTFSROOTHASH_SIGNATURE = "${IMAGENAME}-${MACHINE}.ext4.roothash.signature"
FITIMAGE = "${FITIMAGE_NAME}.itb.signed"
FITIMAGEUUU = "${FITIMAGE_UUU_NAME}.itb.signed"
KERNELIMAGE ?= "Image"
KERNELDTB ?= ""
INITRAMFS ?= ""

# set output directory and file names
UUU_DEPLOY_DIR = "${DEPLOYDIR}/${PN}"
UUU_DEPLOY_TAR = "${DEPLOYDIR}/${PN}-container.tar.gz"

# File names in deploy directory
FLASHBINDEPLOY ?= "flash.bin.signed"
HASHSUMS = "hashsums"
ROOTFSDEPLOY = "rootfs.${ROOTFS_EXT}"
ROOTFSVERITYDEPLOY = "rootfs.ext4.hashdevice"
ROOTFSROOTHASHDEPLOY = "rootfs.ext4.roothash"
ROOTFSROOTHASHDEPLOY_SIGNATURE = "rootfs.ext4.roothash.signature"
PARTITIONSDEPLOY = "partitions"
UUUSCRIPTDEPLOY = "flashall.uuu"
VERIFICATIONSCRIPTDEPLOY = "verification.sh"
FITIMAGEDEPLOY = "fitImage.signed"
FITIMAGEUUUDEPLOY = "fitImage-uuu.signed"
KERNELIMAGEDEPLOY = "Image"
KERNELDTBDEPLOY = "${KERNELDTB}"
INITRAMFSDEPLOY = "${INITRAMFS}"

# The following line forces the usage of the "files" directory next to this .inc file even if it is required from another layer
FILESEXTRAPATHS:prepend := "${@os.path.dirname(d.getVar('FILE'))}/files:"

SRC_URI = " \
    file://${PARTITIONS} \
    file://${UUUSCRIPT} \
    ${@bb.utils.contains('USE_VERIFICATION_SCRIPT', '1', 'file://${VERIFICATIONSCRIPT}', '', d)} \
"

do_deploy () {
    install -d ${UUU_DEPLOY_DIR}
    install -m 0644 ${WORKDIR}/recipe-sysroot/${FLASHBIN} ${UUU_DEPLOY_DIR}/${FLASHBINDEPLOY}

    install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFS} ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY}
    if [ "${USE_ROOTFS_DMVERITY}" = "1" ]
    then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFSVERITY} ${UUU_DEPLOY_DIR}/${ROOTFSVERITYDEPLOY}
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFSROOTHASH} ${UUU_DEPLOY_DIR}/${ROOTFSROOTHASHDEPLOY}
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFSROOTHASH_SIGNATURE} ${UUU_DEPLOY_DIR}/${ROOTFSROOTHASHDEPLOY_SIGNATURE}
    fi
    if [ "${USE_FITIMAGES}" = "1" ]
    then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${FITIMAGE} ${UUU_DEPLOY_DIR}/${FITIMAGEDEPLOY}
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${FITIMAGEUUU} ${UUU_DEPLOY_DIR}/${FITIMAGEUUUDEPLOY}
    else
        # handle kernel image, dtb and initramfs seperately
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${KERNELIMAGE} ${UUU_DEPLOY_DIR}/${KERNELIMAGEDEPLOY}
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${KERNELDTB} ${UUU_DEPLOY_DIR}/${KERNELDTBDEPLOY}
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${INITRAMFS} ${UUU_DEPLOY_DIR}/${INITRAMFSDEPLOY}
    fi

    install -m 0644 ${WORKDIR}/${PARTITIONS} ${UUU_DEPLOY_DIR}/${PARTITIONSDEPLOY}
    install -m 0644 ${WORKDIR}/${UUUSCRIPT} ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}

    if [ "${DEPLOY_SNAKEOIL_KEYS}" = "1" ]
    then
        # add encryption key
        if [ ! -e "${SWUPDATE_AES_SNAKEOIL_FILE}" ]; then
            bbfatal "SWUPDATE_AES_SNAKEOIL_FILE=$SWUPDATE_AES_SNAKEOIL_FILE does not exist!"
        fi
        key=`cat ${SWUPDATE_AES_SNAKEOIL_FILE} | grep ^key | cut -d '=' -f 2`
        iv=`cat ${SWUPDATE_AES_SNAKEOIL_FILE} | grep ^iv | cut -d '=' -f 2`
        if [ -z "${key}" ] || [ -z "${iv}" ];then
            bbfatal "SWUPDATE_AES_SNAKEOIL_FILE=$SWUPDATE_AES_SNAKEOIL_FILE does not contain valid keys"
        fi
        echo "${key} ${iv}" > ${WORKDIR}/swupdate_snakeoil_encryption.key
        install -m 644 ${WORKDIR}/swupdate_snakeoil_encryption.key ${UUU_DEPLOY_DIR}/swupdate_snakeoil_encryption.key

        # add identity key and cert
        install -m 644 "${IDENTITY_SNAKEOIL_KEY}" ${UUU_DEPLOY_DIR}/sensor_identity_snakeoil.key
        install -m 644 "${IDENTITY_SNAKEOIL_CRT}" ${UUU_DEPLOY_DIR}/sensor_identity_snakeoil.crt
    fi

    if [ "${USE_VERIFICATION_SCRIPT}" = "1" ]
    then
        install -m 0644 ${WORKDIR}/${VERIFICATIONSCRIPT} ${UUU_DEPLOY_DIR}/${VERIFICATIONSCRIPTDEPLOY}

        # for hashsum check, calculate the hashsums of the original files and store them into one file
        # If a file exists so far, delete it
        rm -f ${UUU_DEPLOY_DIR}/${HASHSUMS}

        # Read out the hashsum and store it into variable hash_flashbin without the path output of sha256sum
        hash_flashbin=$(sha256sum ${UUU_DEPLOY_DIR}/${FLASHBINDEPLOY} | cut -d' ' -f1)
        # Write the formatted value together with a variable into hashsum file
        echo "HASH_FLASHBIN=\"$hash_flashbin\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}
        # Calculate the size for partition check
        size_flashbin="$(stat --printf=%s ${UUU_DEPLOY_DIR}/${FLASHBINDEPLOY})"
        echo "SIZE_FLASHBIN=\"$size_flashbin\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}

        hash_fitimage=$(sha256sum ${UUU_DEPLOY_DIR}/${FITIMAGEDEPLOY} | cut -d' ' -f1)
        echo "HASH_FITIMAGE=\"$hash_fitimage\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}

        hash_rootfs=$(zcat ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY} | sha256sum - | cut -d' ' -f1)
        echo "HASH_ROOTFS=\"$hash_rootfs\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}
        # Calculate the size for partition check: Decompress rootfs.ext4.gz virtually and evaluate the size with wc
        size_rootfs="$(zcat ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY} | wc -c)"
        echo "SIZE_ROOTFS=\"$size_rootfs\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}

        size_rootfsverity="$(stat --printf=%s ${UUU_DEPLOY_DIR}/${ROOTFSVERITYDEPLOY})"
        echo "SIZE_ROOTFSVERITY=\"$size_rootfsverity\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}
    fi

    cd ${DEPLOYDIR} && tar -czv ${PN} -f ${UUU_DEPLOY_TAR}
    rm -rf ${UUU_DEPLOY_DIR}
}

addtask do_deploy after do_install
