# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

IMAGENAME = "${@ d.getVar('PN').replace('-uuu','')}"
inherit deploy

# Depend on image (read from PN), initrams, kernel and imx-boot (u-boot)
do_install[depends] = "\
	${IMAGENAME}:do_image_complete \
	${INITRAMFSNAME}:do_image_complete \
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
KERNEL = "Image-${MACHINE}.bin"
ROOTFS = "${IMAGENAME}-${MACHINE}-*.rootfs.ext4.gz"
# Although the flashall.uuu script as well as the verification.sh script only differ in the dtb-file name, 
# they are created specifically for each of the available machines and stored and used as separate files:
# First, a template doesn't leave much space for adaptations and would depend on the recipe being executed.
# Second, the independence between Yocto and the content of the hashsum toolchain shall be guaranteed.
# That's why, only the partitions file is used for all machines with the adapted weak setting.
PARTITIONS ?= "partitions_${MACHINE}"
UUUSCRIPT = "flashall_${MACHINE}.uuu"
VERIFICATIONSCRIPT = "verification_${MACHINE}.sh"
INITRAMFS = "${INITRAMFSNAME}-${MACHINE}-*.rootfs.cpio.gz.u-boot"

# set output directory and file names
UUU_DEPLOY_DIR = "${DEPLOYDIR}/${PN}"

FLASHBINDEPLOY = "flash.bin"
KERNELDEPLOY = "Image"
DEVTREEDEPLOY = "devicetree.dtb"
HASHSUMS = "hashsums"
ROOTFSDEPLOY = "rootfs.ext4.gz"
PARTITIONSDEPLOY = "partitions"
UUUSCRIPTDEPLOY = "flashall.uuu"
VERIFICATIONSCRIPTDEPLOY = "verification.sh"
INITRAMFSDEPLOY = "rootfs.cpio.gz.u-boot"

# The following line forces the usage of the "files" directory next to this .inc file even if it is required from another layer
FILESEXTRAPATHS_prepend := "${@os.path.dirname(d.getVar('FILE'))}/files:"

SRC_URI = "file://${PARTITIONS} file://${UUUSCRIPT} file://${VERIFICATIONSCRIPT}"

do_deploy () {
	install -d ${UUU_DEPLOY_DIR}
	install -m 0644 ${WORKDIR}/recipe-sysroot/${FLASHBIN} ${UUU_DEPLOY_DIR}/${FLASHBINDEPLOY}
	
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${KERNEL} ${UUU_DEPLOY_DIR}/${KERNELDEPLOY}
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${DEVTREE} ${UUU_DEPLOY_DIR}/${DEVTREEDEPLOY}
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFS} ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY}
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${INITRAMFS} ${UUU_DEPLOY_DIR}/${INITRAMFSDEPLOY}

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

    hash_kernel=$(sha256sum ${UUU_DEPLOY_DIR}/${KERNELDEPLOY} | cut -d' ' -f1)
    echo "HASH_KERNEL=\"$hash_kernel\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}

    hash_devtree=$(sha256sum ${UUU_DEPLOY_DIR}/${DEVTREEDEPLOY} | cut -d' ' -f1)
    echo "HASH_DEVTREE=\"$hash_devtree\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}

    hash_rootfs=$(zcat ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY} | sha256sum - | cut -d' ' -f1)
    echo "HASH_ROOTFS=\"$hash_rootfs\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}
    # Calculate the size for partition check: Decompress rootfs.ext4.gz virtually and evaluate the size with wc
    size_rootfs="$(zcat ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY} | wc -c)"
    echo "SIZE_ROOTFS=\"$size_rootfs\"" >> ${UUU_DEPLOY_DIR}/${HASHSUMS}
}

addtask do_deploy after do_install
