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
PARTITIONS = "partitions_${MACHINE}"
UUUSCRIPT = "flashall_${MACHINE}.uuu"
INITRAMFS = "${INITRAMFSNAME}-${MACHINE}-*.rootfs.cpio.gz.u-boot"

# set output directory and file names
UUU_DEPLOY_DIR = "${DEPLOYDIR}/${PN}"

FLASHBINDEPLOY = "flash.bin"
KERNELDEPLOY = "Image"
DEVTREEDEPLOY = "devicetree.dtb"
ROOTFSDEPLOY = "rootfs.ext4.gz"
PARTITIONSDEPLOY = "partitions"
UUUSCRIPTDEPLOY = "flashall.uuu"
INITRAMFSDEPLOY = "rootfs.cpio.gz.u-boot"

# The following line forces the usage of the "files" directory next to this .inc file even if it is required from another layer
FILESEXTRAPATHS_prepend := "${@os.path.dirname(d.getVar('FILE'))}/files:"

SRC_URI = "file://${PARTITIONS} file://${UUUSCRIPT}"

do_deploy () {
	install -d ${UUU_DEPLOY_DIR}
	install -m 0644 ${WORKDIR}/recipe-sysroot/${FLASHBIN} ${UUU_DEPLOY_DIR}/${FLASHBINDEPLOY}
	
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${KERNEL} ${UUU_DEPLOY_DIR}/${KERNELDEPLOY}
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${DEVTREE} ${UUU_DEPLOY_DIR}/${DEVTREEDEPLOY}
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${ROOTFS} ${UUU_DEPLOY_DIR}/${ROOTFSDEPLOY}
	install -m 0644 ${DEPLOY_DIR_IMAGE}/${INITRAMFS} ${UUU_DEPLOY_DIR}/${INITRAMFSDEPLOY}

	install -m 0644 ${WORKDIR}/${PARTITIONS} ${UUU_DEPLOY_DIR}/${PARTITIONSDEPLOY}
	install -m 0644 ${WORKDIR}/${UUUSCRIPT} ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}
}

addtask do_deploy after do_install
