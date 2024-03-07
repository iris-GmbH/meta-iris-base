# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

# IRMA6R2 SoC specific packages (not included in qemu)
CORE_IMAGE_BASE_INSTALL:append:use-irma6r2-bsp = " \
   lvm2 \
   cryptsetup \
   keyctl-caam \
   util-linux-blockdev \
   keyutils \
   bc \
"

CORE_IMAGE_BASE_INSTALL:append:use-irma-matrix-bsp = " \
    tar \
    zstd \
"

# Overwrite default IMAGE_FSTYPES for the initramfs
IMAGE_FSTYPES:use-irma6r2-bsp = "cpio.gz"
IMAGE_FSTYPES:use-irma-matrix-bsp = "cpio.zst"

# Remove not needed dependencies to speed up build time
DEPENDS:remove = "u-boot-mfgtool linux-mfgtool"
