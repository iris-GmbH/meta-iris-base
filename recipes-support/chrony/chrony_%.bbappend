# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

SRC_URI_append := " \
	file://chrony.conf \
"

FILES_${PN}_append += " \
		${sysconfdir} \
		${sysconfdir}/default \
		${sysconfdir}/default/chrony.conf \
		"

DEPENDS += " \
	pkgconfig \
	nettle \
	gnutls \
"

do_configure_prepend() {
    export PKG_CONFIG="/usr/bin/pkg-config"
    export PKG_CONFIG_PATH="${WORKDIR}/recipe-sysroot/usr/lib/pkgconfig/"
    export alias shell='/bin/sh'
}

do_install_append() {
    install -d ${D}/${sysconfdir}/default
    install -m 0755 ${WORKDIR}/chrony.conf ${D}/${sysconfdir}/default/chrony.conf
}
