# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

# require inc-file from meta-secure-imx
require recipes-core/images/image-fit.inc

COMPATIBLE_MACHINE = "mx8"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

KERNEL_SIGN_SUFFIX = "signed"
RESCUE_NAME_FULL ?= "${RESCUE_NAME}-${MACHINE}.cpio.gz"

# Overwrite KERNEL_DEVICETREE as it is a multiline variable defined in meta-freescale/conf/machine
KERNEL_DEVICETREE_imx8mpevk = "freescale/imx8mp-evk.dtb"

# Define load addresses for imx8mp hardware
ITS_KERNEL_LOAD_ADDR_mx8mp = "0x40480000"
ITS_KERNEL_ENTRY_ADDR_mx8mp = "0x40480000"
FITLOADADDR_mx8mp = "0x48000000"

# include checking of HAB/CST related variables
inherit irma6-signing-variable-check
addtask do_signing_variable_check before do_assemble_fit

do_assemble_fit:prepend() {
	if [ -z "${FITLOADADDR}" ]; then
		FITLOADADDR=0x48000000
		bbwarn "Set FITLOADADDR to ${FITLOADADDR}"
	fi

	if [ -z "${RESCUE_NAME_FULL}" ]; then
		bbwarn "RESCUE_NAME_FULL is not set"
	fi

	if [ -z "${FITIMAGE_DESCRIPTION}" ]; then
		bbwarn "FITIMAGE_DESCRIPTION is not set"
	fi

	if [ -z "${FITIMAGE_RUNNING_VERSION}" ]; then
		FITIMAGE_RUNNING_VERSION=0.0.0
		bbwarn "Set FITIMAGE_RUNNING_VERSION to ${FITIMAGE_RUNNING_VERSION}"
	fi

	if [ -z "${ITS_KERNEL_LOAD_ADDR}" ]; then
		bbwarn "ITS_KERNEL_LOAD_ADDR is not set"
	fi

	if [ -z "${ITS_KERNEL_ENTRY_ADDR}" ]; then
		bbwarn "ITS_KERNEL_ENTRY_ADDR is not set"
	fi
}

# overwrite meta-secure-imx/recipes-core/images/image-fit.inc
do_assemble_fit() {
	echo "STAGING_KERNEL_DIR" ${STAGING_KERNEL_DIR}
	echo "STAGING_KERNEL_BUILDDIR" ${STAGING_KERNEL_BUILDDIR}
	echo "KERNEL_SRC_PATH" ${KERNEL_SRC_PATH}
	export DEPLOY_DIR_IMAGE=${DEPLOY_DIR_IMAGE}
	export KERNEL_DEVICETREE=${KERNEL_DEVICETREE}
	export RESCUE_NAME_FULL=${RESCUE_NAME_FULL}
	export FITIMAGE_DESCRIPTION="${FITIMAGE_DESCRIPTION}"
	export FITIMAGE_RUNNING_VERSION=${FITIMAGE_RUNNING_VERSION}
	export MACHINE=${MACHINE}
	export ITS_KERNEL_LOAD_ADDR=${ITS_KERNEL_LOAD_ADDR}
	export ITS_KERNEL_ENTRY_ADDR=${ITS_KERNEL_ENTRY_ADDR}
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
	sed -i "s|KERNEL_DEVICETREE|$(basename $KERNEL_DEVICETREE)|g" rescue.its
	sed -i "s|ITS_KERNEL_LOAD_ADDR|$ITS_KERNEL_LOAD_ADDR|g" rescue.its
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

	prepare_hab_image ${ITB_FNAME}
	install ${ITB_FNAME}-ivt.${KERNEL_SIGN_SUFFIX} ${DEPLOY_DIR_IMAGE}/${ITB_FNAME}.${KERNEL_SIGN_SUFFIX}
}

# overwrite meta-secure-imx/classes/fitimage-hab-sign.bbclass
csf_emit_file() {
	cat << EOF > ${1}
[Header]
Version = 4.5
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS
Engine = ${7}

[Install SRK]
File = "${2}"
Source index = 0

[Install CSFK]
File = "${3}"

[Authenticate CSF]

[Install Key]
Verification index = 0
Target Index = 2
File= "${4}"

[Authenticate Data]
Verification index = 2
Blocks = ${5} "${6}"

[Unlock]
Engine = ${7}
Features = RNG
EOF
}

