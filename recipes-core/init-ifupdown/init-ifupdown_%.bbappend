# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://eth0-pre-up \
"
FILES:${PN} += "${sysconfdir}/network/if-pre-up.d/eth0-pre-up "

do_install:append() {
    install -d ${D}${sysconfdir}/network/if-pre-up.d
    install -m 0755 ${WORKDIR}/eth0-pre-up ${D}${sysconfdir}/network/if-pre-up.d/
}
