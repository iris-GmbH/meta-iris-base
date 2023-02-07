# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

CORE_IMAGE_BASE_INSTALL:append = " \
    lvm2 \
    cryptsetup \
"

# IRMA6R2 SoC specific packages (not included in qemu)
CORE_IMAGE_BASE_INSTALL:append:mx8mp = " \
   keyctl-caam \
   util-linux-blockdev \
   keyutils \
   bc \
"

# Add the "cpio.gz" image type to use this initramfs for a fitimage
IMAGE_FSTYPES:append = " cpio.gz"

# Remove not needed dependencies to speed up build time
DEPENDS:remove = "u-boot-mfgtool linux-mfgtool"
