# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

require uuu-container.inc

USE_ROOTFS_DMVERITY = "0"
DEPLOY_SNAKEOIL_KEYS = "0"
FLASHBIN:imx93-11x11-lpddr4x-evk = "boot/imx-boot-imx93-11x11-lpddr4x-evk-sd.bin-flash_singleboot_no_ahabfw"
UUUSCRIPT:imx93-11x11-lpddr4x-evk = "flashall_imx93evk.uuu"
VERIFICATIONSCRIPT:imx93-11x11-lpddr4x-evk = "verification_imx93evk.sh"

# only allow iMX93 (= irma-matrix) machines
COMPATIBLE_MACHINE = "mx93-nxp-bsp"

