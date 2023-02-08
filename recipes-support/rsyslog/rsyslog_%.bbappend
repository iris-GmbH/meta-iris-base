# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append := " \
	file://rsyslog.conf \
"

FILES:${PN}:append += " \
		${sysconfdir} \
		${sysconfdir}/rsyslog.conf \
		"

do_install:append() {
	# copy config to /etc/rsyslog.conf
	install -d ${D}/${sysconfdir}
	install -m 0755 ${WORKDIR}/rsyslog.conf ${D}/${sysconfdir}/rsyslog.conf
}
