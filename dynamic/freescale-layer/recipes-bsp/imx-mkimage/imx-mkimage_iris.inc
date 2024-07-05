# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:imx8mp-irma6r2 = " \
    file://0001-LFU-573-1-imx8m-Generate-hash-of-FIT-FDT-structure-t.patch \
"

# imx93 (mx93-nxp-bsp) requires a newer imx-mkimage release
SRCBRANCH:mx93-nxp-bsp = "lf-6.1.55_2.2.0"
SRCREV:mx93-nxp-bsp = "c4365450fb115d87f245df2864fee1604d97c06a"
SRC_URI:mx93-nxp-bsp = "git://github.com/nxp-imx/imx-mkimage.git;protocol=https;branch=${SRCBRANCH}"
