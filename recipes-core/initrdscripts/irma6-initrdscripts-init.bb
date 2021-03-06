# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

require irma6-initrdscripts.inc

# IRMA6R2 SoC specific packages (not included in qemu)
RDEPENDS_${PN}_append_mx8mp = " \
    keyctl-caam \
    util-linux-blockdev \
    keyutils \
"

