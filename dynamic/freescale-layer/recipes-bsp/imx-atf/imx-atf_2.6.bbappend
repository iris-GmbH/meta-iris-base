# SPDX-License-Identifier: MIT
# Copyright (C) 2023 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://0001-Revert-MA-20141-imx8m-enable-alarm-when-shutdown.patch \
    file://0002-bl31-Use-UART-3-for-debug-output.patch \
"
