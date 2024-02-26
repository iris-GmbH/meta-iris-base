# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

include u-boot-imx_iris.inc

# add the file containing the u-boot version string to the sysroot,
# so that we can consume it within other recipes.
FILES:${PN}-dev += "${datadir}/uboot.release"
do_install:append() {
    install -d ${D}/${datadir}
    install ${B}/.scmversion ${D}${datadir}/uboot.release
}
