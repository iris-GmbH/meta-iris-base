# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://imx8mp-evk-r2_defconfig \
"

KERNEL_DEFCONFIG_imx8mpevk = "imx8mp-evk-r2_defconfig"
