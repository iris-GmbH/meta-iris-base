# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

# imx93evk (use-irma-matrix-bsp) requires a newer imx-mkimage release
SRCBRANCH:use-irma-matrix-bsp = "lf-6.1.55_2.2.0"
SRCREV:use-irma-matrix-bsp = "c4365450fb115d87f245df2864fee1604d97c06a"
SRC_URI:use-irma-matrix-bsp = "git://github.com/nxp-imx/imx-mkimage.git;protocol=https;branch=${SRCBRANCH}"
