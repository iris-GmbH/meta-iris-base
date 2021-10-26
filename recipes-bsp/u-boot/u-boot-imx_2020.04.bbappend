# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"
SRC_URI += "\
	file://0001-Backport-cmd-fs-Use-part_get_info_by_dev_and_name_or.patch"

