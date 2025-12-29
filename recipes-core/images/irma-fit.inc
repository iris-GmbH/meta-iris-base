# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

SUMMARY = "IRMA FIT image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = " \
	file://rescue.its.in \
"

DEPENDS += " \
	dtc-native \
	u-boot-mkimage-native \
"

do_assemble_fit[depends] += "virtual/kernel:do_deploy"

do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_assemble_fit[nostamp] = "1"
do_package[noexec] = "1"
do_packagedata[noexec] = "1"
deltask package_write_ipk
deltask package_write_deb
deltask package_write_rpm
deltask do_deploy_archives
deltask do_rootfs

S = "${WORKDIR}"
B = "${S}"

ITB_FNAME = "${PN}.itb"
FITIMAGE_RUNNING_VERSION = "1.0"
FITIMAGE_RUNNING_VERSION:mx8mp-nxp-bsp = "2.0"
FITIMAGE_DESCRIPTION = "IRMA FIT image"
RESCUE_NAME_FULL ?= "${RESCUE_NAME}-${MACHINE}.cpio.zst"

# Overwrite KERNEL_DEVICETREE as it is a multiline variable defined in meta-freescale/conf/machine
KERNEL_DTB_FILE = "${@' '.join([d for d in '${KERNEL_DEVICETREE}'.split() if d.endswith('.dtb')])}"
KERNEL_DTBO_REV3_FILE:mx8mp-nxp-bsp = "${@' '.join([d for d in '${KERNEL_DEVICETREE}'.split() if d.endswith('.dtbo')])}"

KERNEL_DTB_FILE:imx8mp-lpddr4-evk = "freescale/imx8mp-evk.dtb"
KERNEL_DTB_FILE:imx93-11x11-lpddr4x-evk = "freescale/imx93-11x11-evk-marec-fpga.dtb"

# Define load addresses for imx8mp hardware
ITS_KERNEL_LOAD_ADDR:mx8mp-nxp-bsp = "0x40400000"
ITS_KERNEL_ENTRY_ADDR:mx8mp-nxp-bsp = "0x40400000"
ITS_DTB_LOAD_ADDR:mx8mp-nxp-bsp = "0x43000000"
ITS_DTBO_REV3_LOAD_ADDR:mx8mp-nxp-bsp = "0x43100000"

# Define load addresses for imx93 hardware
ITS_KERNEL_LOAD_ADDR:mx9-nxp-bsp = "0x80400000"
ITS_KERNEL_ENTRY_ADDR:mx9-nxp-bsp = "0x80400000"
ITS_DTB_LOAD_ADDR:mx9-nxp-bsp = "0x83000000"


do_assemble_fit() {
	echo "STAGING_KERNEL_DIR" ${STAGING_KERNEL_DIR}
	echo "STAGING_KERNEL_BUILDDIR" ${STAGING_KERNEL_BUILDDIR}
	echo "KERNEL_SRC_PATH" ${KERNEL_SRC_PATH}
	export DEPLOY_DIR_IMAGE=${DEPLOY_DIR_IMAGE}
	export KERNEL_DTB_FILE=${KERNEL_DTB_FILE}
	export KERNEL_DTBO_REV3_FILE=${KERNEL_DTBO_REV3_FILE}
	export RESCUE_NAME_FULL=${RESCUE_NAME_FULL}
	export FITIMAGE_DESCRIPTION="${FITIMAGE_DESCRIPTION}"
	export FITIMAGE_RUNNING_VERSION=${FITIMAGE_RUNNING_VERSION}
	export MACHINE=${MACHINE}
	export ITS_KERNEL_LOAD_ADDR=${ITS_KERNEL_LOAD_ADDR}
	export ITS_KERNEL_ENTRY_ADDR=${ITS_KERNEL_ENTRY_ADDR}
	export ITS_DTB_LOAD_ADDR=${ITS_DTB_LOAD_ADDR}
	export ITS_DTBO_REV3_LOAD_ADDR=${ITS_DTBO_REV3_LOAD_ADDR}
	export KERNEL_IMAGETYPE=${KERNEL_IMAGETYPE}
	if [ "${KERNEL_IMAGETYPE}" = "Image.gz" ]; then
		export KERNEL_COMPRESSION=gzip
	else
		export KERNEL_COMPRESSION=none
	fi
	if [ "${TARGET_ARCH}" = "aarch64" ]; then
		export TARGET_ARCH=arm64
	else
		export TARGET_ARCH=${TARGET_ARCH}
	fi
	echo "B" ${B}
	echo "S" ${S}
	echo $DEPLOY_DIR_IMAGE
	echo "FNAME " ${ITB_FNAME}
	cd ${B}
	cp ${B}/rescue.its.in ${B}/rescue.its
	sed -i "s|DEPLOY_DIR_IMAGE|$DEPLOY_DIR_IMAGE|g" rescue.its
	sed -i "s|RESCUE_NAME_FULL|$RESCUE_NAME_FULL|g" rescue.its
	sed -i "s|FITIMAGE_DESCRIPTION|$FITIMAGE_DESCRIPTION|g" rescue.its
	sed -i "s|FITIMAGE_RUNNING_VERSION|$FITIMAGE_RUNNING_VERSION|g" rescue.its
	sed -i "s|MACHINE|$MACHINE|g" rescue.its
	sed -i "s|TARGET_ARCH|$TARGET_ARCH|g" rescue.its
	sed -i "s|KERNEL_IMAGETYPE|$KERNEL_IMAGETYPE|g" rescue.its
	sed -i "s|KERNEL_COMPRESSION|$KERNEL_COMPRESSION|g" rescue.its
	sed -i "s|KERNEL_DTB_FILE|$(basename $KERNEL_DTB_FILE)|g" rescue.its
	sed -i "s|ITS_KERNEL_LOAD_ADDR|$ITS_KERNEL_LOAD_ADDR|g" rescue.its
	sed -i "s|ITS_DTB_LOAD_ADDR|$ITS_DTB_LOAD_ADDR|g" rescue.its
	sed -i "s|KERNEL_DTBO_REV3_FILE|$(basename $KERNEL_DTBO_REV3_FILE)|g" rescue.its
	sed -i "s|ITS_DTBO_REV3_LOAD_ADDR|$ITS_DTBO_REV3_LOAD_ADDR|g" rescue.its
	sed -i "s|ITS_KERNEL_ENTRY_ADDR|$ITS_KERNEL_ENTRY_ADDR|g" rescue.its
	cat rescue.its
	echo "======== create itb file ==========="
	uboot-mkimage -D "-I dts -O dtb -p 0x1000" -f rescue.its ${ITB_FNAME}
		if [ $? -ne 0 ]; then
		echo create FIT image failed
		exit 1
	fi

	install -d ${DEPLOY_DIR_IMAGE}
	install -m 644 ${ITB_FNAME} ${DEPLOY_DIR_IMAGE}/${ITB_FNAME}
}

addtask do_assemble_fit before do_install after do_compile

FITIMAGE_IMAGE_NAME = "${ITB_FNAME}"
HAB_INHERIT = "hab-signed-fitimage"
HAB_INHERIT:poky-iris-0601 = ""
inherit ${HAB_INHERIT}
