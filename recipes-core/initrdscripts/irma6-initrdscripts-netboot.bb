# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

require irma6-initrdscripts.inc

RDEPENDS_${PN}_append = " nfs-utils"

SCRIPTFILE = "initramfs-init-netboot.sh"

