# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

CORE_IMAGE_BASE_INSTALL_append = " \
    lvm2 \
    cryptsetup \
"

# Add the "cpio.gz" image type to use this initramfs for a fitimage
IMAGE_FSTYPES_append = " cpio.gz"
