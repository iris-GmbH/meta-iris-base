# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

include linux-fslc-iris.inc

# Hack: Bump Linux to include CAAM Drivers
SRCBRANCH = "5.4-2.3.x-imx"
SRCREV = "712fcc850e5a6d0867b0d97a0b79f1addd01998f"
LINUX_VERSION = "5.4.161"
LOCALVERSION = "-imx-5.4.24-2.3.0"
