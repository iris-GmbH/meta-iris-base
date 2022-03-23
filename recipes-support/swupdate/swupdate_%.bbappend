# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
SRC_URI_append := "file://defconfig"

RDEPENDS_${PN} += "util-linux-sfdisk jq"
FILES_${PN} += "${SWUPDATE_HW_COMPATIBILITY_FILE}"

do_install_append () {
	install -d $(basename -- ${D}${SWUPDATE_HW_COMPATIBILITY_FILE})

	# all machines are v1.0 for now
	echo "${MACHINE} 1.0" > ${D}${SWUPDATE_HW_COMPATIBILITY_FILE}
}
