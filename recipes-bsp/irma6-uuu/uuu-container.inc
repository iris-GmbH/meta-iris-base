# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

IMAGENAME = "${@ d.getVar('PN').replace('-uuu','')}"
inherit deploy

# Depend on image (read from PN), initrams, kernel and imx-boot (u-boot)
do_install[depends] = "\
    ${IMAGENAME}:do_image_complete \
    irma6-fitimage:do_assemble_fit \
    irma6-fitimage-uuu:do_assemble_fit \
    virtual/kernel:do_deploy"
DEPENDS = "imx-boot"
COMPATIBLE_MACHINE = "mx8"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# skip tasks, as we only want to deploy things
do_configure[noexec] = "1"
do_install[noexec] = "1"
do_compile[noexec] = "1"
do_deploy[nostamp] = "1"

# set generic file names that should match for most images
ROOTFS = "${IMAGENAME}-${MACHINE}-*.rootfs.ext4.gz"
ROOTFSVERITY = "${IMAGENAME}-${MACHINE}-*.rootfs.ext4.hashdevice"
ROOTFSROOTHASH = "${IMAGENAME}-${MACHINE}-*.rootfs.ext4.roothash"
PARTITIONS ?= "partitions_${MACHINE}"
UUUSCRIPT ?= "flashall_${MACHINE}.uuu"
VERIFICATIONSCRIPT ?= "verification_${MACHINE}.sh"
FITIMAGE = "irma6-fitimage.itb.signed"
FITIMAGEUUU = "irma6-fitimage-uuu.itb.signed"

# set output directory and file names
UUU_DEPLOY_DIR = "${DEPLOYDIR}/${PN}"

FLASHBINDEPLOY = "flash.bin.signed"
HASHSUMS = "hashsums"
ROOTFSDEPLOY = "rootfs.ext4.gz"
ROOTFSVERITYDEPLOY = "rootfs.ext4.hashdevice"
ROOTFSROOTHASHDEPLOY = "rootfs.ext4.roothash"
PARTITIONSDEPLOY = "partitions"
UUUSCRIPTDEPLOY = "flashall.uuu"
VERIFICATIONSCRIPTDEPLOY = "verification.sh"
FITIMAGEDEPLOY = "fitImage.signed"
FITIMAGEUUUDEPLOY = "fitImage-uuu.signed"

# The following line forces the usage of the "files" directory next to this .inc file even if it is required from another layer
FILESEXTRAPATHS_prepend := "${@os.path.dirname(d.getVar('FILE'))}/files:"

SRC_URI = "file://${PARTITIONS} file://${UUUSCRIPT} file://${VERIFICATIONSCRIPT}"

do_deploy () {
    install -d ${UUU_DEPLOY_DIR}
    install -m 0644 ${WORKDIR}/recipe-sysroot/${FLASHBIN} ${UUU_DEPLOY_DIR}/${FLASHBINDEPLOY}

    install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFS} ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFSVERITY} ${UUU_DEPLOY_DIR}/${ROOTFSVERITYDEPLOY}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFSROOTHASH} ${UUU_DEPLOY_DIR}/${ROOTFSROOTHASHDEPLOY}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${FITIMAGE} ${UUU_DEPLOY_DIR}/${FITIMAGEDEPLOY}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/${FITIMAGEUUU} ${UUU_DEPLOY_DIR}/${FITIMAGEUUUDEPLOY}

    install -m 0644 ${WORKDIR}/${PARTITIONS} ${UUU_DEPLOY_DIR}/${PARTITIONSDEPLOY}
    install -m 0644 ${WORKDIR}/${UUUSCRIPT} ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}
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
}

addtask do_deploy after do_install
