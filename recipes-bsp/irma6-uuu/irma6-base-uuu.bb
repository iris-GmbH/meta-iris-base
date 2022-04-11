# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

require uuu-container.inc

INITRAMFSNAME = "fsl-image-mfgtool-initramfs"

FLASHBIN_imx8mpevk = "boot/imx-boot-imx8mpevk-sd.bin-flash_evk"
FLASHBIN_imx8mp-irma6r2 = "boot/imx-boot-imx8mp-irma6r2-sd.bin-flash_ddr4_evk"
DEVTREE_imx8mpevk = "imx8mp-evk.dtb"
DEVTREE_imx8mp-irma6r2 = "imx8mp-irma6r2.dtb"
PARTITIONS_imx8mpevk = "partitions_imx8mp"
PARTITIONS_imx8mp-irma6r2 = "partitions_imx8mp"
