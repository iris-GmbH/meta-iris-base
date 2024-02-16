# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

# use recipe from meta-secure-imx as base
require recipes-core/images/crypt-image-initramfs.inc

INITRAMFS_COMMON_PACKAGES:remove = " \
    u-boot-env \
    libubootenv-bin \
    initramfs-init \
"

INITRAMFS_COMMON_PACKAGES:append = " \
    ${INITSCRIPT_PACKAGE} \
"

PACKAGE_INSTALL = "${INITRAMFS_COMMON_PACKAGES}"

