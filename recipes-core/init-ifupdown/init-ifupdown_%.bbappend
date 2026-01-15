# SPDX-License-Identifier: MIT
# Copyright (C) 2022-2025 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

require ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'init-ifupdown-systemd.inc', '', d)}

SRC_URI += " \
    file://eth0-pre-up \
    file://network-helper-script.sh \
"
FILES:${PN} += " \
    ${sysconfdir}/network/if-pre-up.d/eth0-pre-up \
    ${datadir}/iris/network-helper-script.sh \
"

do_install:append() {
    install -d ${D}${sysconfdir}/network/if-pre-up.d
    install -m 0755 ${WORKDIR}/eth0-pre-up ${D}${sysconfdir}/network/if-pre-up.d/
    install -d ${D}${datadir}/iris
    install -m 0755 ${WORKDIR}/network-helper-script.sh ${D}${datadir}/iris/
}
