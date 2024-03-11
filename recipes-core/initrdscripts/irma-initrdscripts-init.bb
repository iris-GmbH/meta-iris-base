# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

require irma-initrdscripts.inc

# IRMA6R2 SoC specific packages (not included in qemu)
RDEPENDS:${PN}:append:mx8mp-nxp-bsp = " \
    keyctl-caam \
    util-linux-blockdev \
    keyutils \
"

SCRIPTFILE:mx93-nxp-bsp = "matrix-initramfs-init.sh"
