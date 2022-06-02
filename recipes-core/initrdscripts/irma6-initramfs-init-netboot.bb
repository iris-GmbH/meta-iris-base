# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

require irma6-initramfs-init.inc

RDEPENDS_${PN}_append = " nfs-utils"

SCRIPTORDER = "bootstrap warnnetboot mountnfs switchroot"


# setenv serverip 10.42.0.1
# setenv nfsroot /srv/nfs_imx8mpevk/
# setenv netfitboot "dhcp; tftp ${fit_addr} ${fit_img}; run netargs; bootm ${fit_addr}"
# saveenv
