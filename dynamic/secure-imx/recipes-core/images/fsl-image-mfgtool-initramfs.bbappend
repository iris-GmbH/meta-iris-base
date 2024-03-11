# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

CORE_IMAGE_BASE_INSTALL:append = " \
    bc \
    lvm2 \
    udev \
"

CORE_IMAGE_BASE_INSTALL:append:use-irma6r2-bsp = " \
   cryptsetup \
   keyctl-caam \
   util-linux-blockdev \
   keyutils \
"

CORE_IMAGE_BASE_INSTALL:append:use-irma-matrix-bsp = " \
    tar \
    zstd \
"

# Overwrite default IMAGE_FSTYPES for the initramfs
IMAGE_FSTYPES = "cpio.zst"

# Remove not needed dependencies to speed up build time
DEPENDS:remove = "u-boot-mfgtool linux-mfgtool"
