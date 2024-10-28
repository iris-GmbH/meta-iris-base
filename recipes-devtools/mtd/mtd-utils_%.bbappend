# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

SRC_URI:append:class-native := " file://use-best-zlib-compression.patch"
FILESEXTRAPATHS:prepend:class-native := "${THISDIR}/${PN}:"
