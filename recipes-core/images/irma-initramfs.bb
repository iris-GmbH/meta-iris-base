# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

require irma-initramfs.inc

# Overwrite default IMAGE_FSTYPES for the initramfs
IMAGE_FSTYPES = "cpio.zst"
