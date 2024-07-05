# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

CORE_IMAGE_BASE_INSTALL:append = " \
    bc \
    lvm2 \
    udev \
    cryptsetup \
    util-linux-blockdev \
"

# irma6r2 specific packages
CORE_IMAGE_BASE_INSTALL:append:mx8mp-nxp-bsp = " \
   keyctl-caam \
   keyutils \
"

# irma-matrix specific packages
CORE_IMAGE_BASE_INSTALL:append:mx93-nxp-bsp = " \
    tar \
    zstd \
"

# Overwrite default IMAGE_FSTYPES for the initramfs
IMAGE_FSTYPES = "cpio.zst"

# Remove not needed dependencies to speed up build time
DEPENDS:remove = "u-boot-mfgtool linux-mfgtool"
