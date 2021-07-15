# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

# add the file containing the u-boot version string to the sysroot,
# so that we can consume it within other recipes.
FILES_${PN}-dev += "${datadir}/uboot.release"
do_install_append() {
    install -d ${D}/${datadir}
    install ${B}/.scmversion ${D}${datadir}/uboot.release
}
