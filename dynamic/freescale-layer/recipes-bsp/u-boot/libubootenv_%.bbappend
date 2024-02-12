# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

# u-boot-env is provided by u-boot-imx
# set rdepend so the -bin package automatically pulls the env package
RDEPENDS:${PN}-bin:append = " u-boot-default-env"

