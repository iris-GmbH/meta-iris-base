# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append := " \
	file://syslog \
	file://syslog-startup.conf \
"


do_install_append() {
	install -d ${sysconfdir}/init.d

	install -m 0755 ${WORKDIR}/syslog ${D}/${sysconfdir}/init.d/
	install -m 0755 ${WORKDIR}/syslog-startup.conf ${D}/${sysconfdir}
}
