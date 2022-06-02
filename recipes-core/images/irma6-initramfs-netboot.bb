# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

# use recipe from meta-secure-imx as base
require recipes-core/images/crypt-image-initramfs.bb

INITRAMFS_COMMON_PACKAGES_remove = " \
    u-boot-env \
    libubootenv-bin \
    initramfs-init \
"

INITRAMFS_COMMON_PACKAGES_append = " \
    irma6-initramfs-init-netboot \
"
