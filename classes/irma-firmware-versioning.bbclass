# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors
#
#
# This file is to be inherited by image recipes as it provides an reliable
# build identifier throughout the development and after release.

FIRMWARE_VERSION = "${@d.getVar('PN', True) + '-' + d.getVar('DISTRO_VERSION', True)}"
