# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris GmbH infrared & intelligent sensors

SRC_URI_append_class-native := "file://use-best-zlib-compression.patch"
FILESEXTRAPATHS_prepend_class-native := "${THISDIR}/${PN}:"
