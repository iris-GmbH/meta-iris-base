# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

require uuu-container.inc

USE_FITIMAGES = "0"
USE_ROOTFS_DMVERITY = "0"
USE_VERIFICATION_SCRIPT = "0"
DEPLOY_SNAKEOIL_KEYS = "0"

KERNELDTB:imx93-matrix-evk = "imx93-11x11-evk.dtb"
INITRAMFS_IMAGE:imx93-matrix-evk = "fsl-image-mfgtool-initramfs"
INITRAMFS:imx93-matrix-evk = "${INITRAMFS_IMAGE}-imx93-matrix-evk.cpio.zst.u-boot"
FLASHBINDEPLOY:imx93-matrix-evk = "flash.bin"
ROOTFS_EXT:imx93-matrix-evk = "tar.zst"

FLASHBIN:imx93-matrix-evk = "boot/imx-boot-imx93-matrix-evk-sd.bin-flash_singleboot_no_ahabfw"
PARTITIONS:imx93-matrix-evk = "partitions_imx93evk"
UUUSCRIPT:imx93-matrix-evk = "flashall_imx93evk.uuu"

COMPATIBLE_MACHINE = "use-irma-matrix-bsp"

# TODO: Use irma6 image for now:
IMAGENAME = "irma6-base"

