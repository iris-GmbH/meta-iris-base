# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

require uuu-container.inc

FLASHBIN:imx8mpevk = "boot/imx-boot-imx8mpevk-sd.bin-flash_evk.signed"
FLASHBIN:imx8mp-irma6r2 = "boot/imx-boot-imx8mp-irma6r2-sd.bin-flash_ddr4_evk.signed"
PARTITIONS:mx8mp-nxp-bsp = "partitions_imx8mp"
UUUSCRIPT:mx8mp-nxp-bsp = "flashall_imx8mp.uuu"
VERIFICATIONSCRIPT:mx8mp-nxp-bsp = "verification_imx8mp.sh"
