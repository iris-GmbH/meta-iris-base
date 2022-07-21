# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append := " \
	file://rsyslog.conf \
"

FILES_${PN}_append += " \
		${sysconfdir} \
		${sysconfdir}/rsyslog.conf \
		"

do_install_append() {
	# copy config to /etc/rsyslog.conf
	install -d ${D}/${sysconfdir}
	install -m 0755 ${WORKDIR}/rsyslog.conf ${D}/${sysconfdir}/rsyslog.conf
}
