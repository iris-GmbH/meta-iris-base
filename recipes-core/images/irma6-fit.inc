# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

# require inc-file from meta-secure-imx
require recipes-core/images/image-fit.inc

COMPATIBLE_MACHINE = "mx8"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

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

do_assemble_fit_prepend() {
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

