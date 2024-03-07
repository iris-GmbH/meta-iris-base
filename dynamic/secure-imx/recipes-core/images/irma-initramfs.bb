# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

# use recipe from meta-secure-imx as base
require irma-initramfs.inc

INITSCRIPT_PACKAGE = "irma-initrdscripts-init"

# Overwrite default IMAGE_FSTYPES for the initramfs
IMAGE_FSTYPES:use-irma6r2-bsp = "cpio.gz"
IMAGE_FSTYPES:use-irma-matrix-bsp = "cpio.zst"
