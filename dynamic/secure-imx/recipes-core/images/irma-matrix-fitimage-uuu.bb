# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

SUMMARY = "IRMA Matrix fitImage with initramfs to be used with uuu/mfgtools"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FITIMAGE_DESCRIPTION = "IRMA Matrix uuu initial operation fitImage"
FITIMAGE_RUNNING_VERSION = "1.0"
RESCUE_NAME = "fsl-image-mfgtool-initramfs"
RESCUE_NAME_FULL = "${RESCUE_NAME}-${MACHINE}.cpio.zst"

require irma-fit.inc
