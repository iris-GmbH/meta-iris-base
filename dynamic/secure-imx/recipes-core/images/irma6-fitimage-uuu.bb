# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

SUMMARY = "IRMA6 FIT image with initramfs to be used with uuu/mfgtools"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FITIMAGE_DESCRIPTION = "IRMA6 uuu initial operation fitimage"
FITIMAGE_RUNNING_VERSION = "1.0"

# name of the recipe, which creates the rescue rootfs
RESCUE_NAME = "fsl-image-mfgtool-initramfs"

require irma6-fit.inc
