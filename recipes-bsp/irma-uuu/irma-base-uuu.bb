# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

require uuu-container.inc
FLASHBIN:imx8mp-lpddr4-evk = "boot/imx-boot-imx8mp-lpddr4-evk-sd.bin-flash_evk.signed"
FLASHBIN:imx8mp-irma6r2 = "boot/imx-boot-imx8mp-irma6r2-sd.bin-flash_ddr4_evk.signed"
FLASHBIN:imx93-11x11-lpddr4x-evk = "boot/imx-boot-imx93-11x11-lpddr4x-evk-sd.bin-flash_singleboot.signed"
FLASHBIN:imx93-matrixup = "boot/imx-boot-imx93-matrixup-sd.bin-flash_singleboot.signed"

UUUSCRIPT:mx8mp-nxp-bsp = "flashall_imx8mp.uuu"
UUUSCRIPT:mx93-nxp-bsp = "flashall_imx93.uuu"

VERIFICATIONSCRIPT:mx8mp-nxp-bsp = "verification_imx8mp.sh"
VERIFICATIONSCRIPT:mx93-nxp-bsp = "verification_imx93.sh"

# only allow iMX machines
COMPATIBLE_MACHINE = "(mx8mp-nxp-bsp|mx93-nxp-bsp)"

