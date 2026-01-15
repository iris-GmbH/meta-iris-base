# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://setup-chrony.sh \
    file://iris-config.conf \
"

FILES:${PN} += " \
    ${bindir}/setup-chrony.sh \
    ${systemd_unitdir}/system/chronyd.service.d/iris-config.conf \
"

DEPENDS += " \
    pkgconfig \
    nettle \
    gnutls \
"

do_configure:prepend() {
    export PKG_CONFIG="/usr/bin/pkg-config"
    export PKG_CONFIG_PATH="${WORKDIR}/recipe-sysroot/usr/lib/pkgconfig/"
    export alias shell='/bin/sh'
}

do_install:append() {
    install -m 0755 ${WORKDIR}/setup-chrony.sh ${D}${bindir}/setup-chrony.sh

    # Create drop-in directory
    install -d ${D}${systemd_unitdir}/system/chronyd.service.d
    install -m 0644 ${WORKDIR}/iris-config.conf ${D}${systemd_unitdir}/system/chronyd.service.d/
}
