# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors
#
#
# This file should be inherited by image recipes as it provides an identical
# version identifier within the running OS itself, as well as inside the
# update_files meta.yml file.

FIRMWARE_VERSION = "${@d.getVar('PN', True) + '-' + d.getVar('PV', True)}"
