# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS:${PN} += "bash"

SRC_URI:append := " \
	file://rsyslog.conf \
	file://udhcp_custom_syslog_option.sh \
"

FILES:${PN}:append = " \
		${sysconfdir} \
		${sysconfdir}/rsyslog.conf \
		${sysconfdir}/udhcpc.d/dhcp_custom_option/udhcp_custom_syslog_option.sh \
		"


udhcp="${D}${sysconfdir}/udhcpc.d"
udhcp_option="${udhcp}/dhcp_custom_option"

do_install:append() {
	# copy config to /etc/rsyslog.conf
	install -d ${D}/${sysconfdir}
	install -d ${udhcp}
	install -d ${udhcp_option}
	install -m 0755 ${WORKDIR}/rsyslog.conf ${D}/${sysconfdir}/rsyslog.conf
	install -m 0755 ${WORKDIR}/udhcp_custom_syslog_option.sh ${udhcp_option}/udhcp_custom_syslog_option.sh
	
}
