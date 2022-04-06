# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append_imx8mp-irma6r2 = " file://0001-Add-imx8mp-irma6r2-SOC-based-on-imx8mp-with-DDR4-fir.patch"

SOC_TARGET_imx8mp-irma6r2 = "iMX8MPI6R2"
