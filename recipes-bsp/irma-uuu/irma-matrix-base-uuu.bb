# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

require uuu-container.inc

USE_ROOTFS_DMVERITY = "0"
DEPLOY_SNAKEOIL_KEYS = "0"

FITIMAGE_NAME = "irma-matrix-fitimage"
FITIMAGE_UUU_NAME = "irma-matrix-fitimage-uuu"
FLASHBIN:imx93-matrix-evk = "boot/imx-boot-imx93-matrix-evk-sd.bin-flash_singleboot_no_ahabfw"
UUUSCRIPT:imx93-matrix-evk = "flashall_imx93evk.uuu"
VERIFICATIONSCRIPT:imx93-matrix-evk = "verification_imx93evk.sh"

COMPATIBLE_MACHINE = "use-irma-matrix-bsp"

# TODO: Use irma6 image for now:
IMAGENAME = "irma6-maintenance"
