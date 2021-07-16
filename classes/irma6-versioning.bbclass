# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors
#
#
# This file is to be inherited by image recipes as it provides an reliable
# build identifier throughout the development and after release.

# If this is a pre-release build, append the build timestamp
FIRMWARE_VERSION = "${@ \
    d.getVar('PN', True) + '-' + d.getVar('PV', True) + '-' + d.getVar('IMAGE_NAME', True)[-14:] \
    if d.getVar('PV', True).endswith('-dev') \
    else \
    d.getVar('PN', True) + '-' + d.getVar('PV', True)}"
