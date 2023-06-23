# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://eth0-pre-up \
    file://eth0-pre-up-maintenance \
"
FILES:${PN} += "${sysconfdir}/network/if-pre-up.d/eth0-pre-up "

do_install:append() {
    #copy eth0-pre-up
    install -d ${D}${sysconfdir}/network/if-pre-up.d
    install -m 0755 ${WORKDIR}/eth0-pre-up ${D}${sysconfdir}/network/if-pre-up.d/
    install -m 0755 ${WORKDIR}/eth0-pre-up-maintenance ${D}${sysconfdir}/network/if-pre-up.d/
}

# Maintenance package
PACKAGES =+ "irma6-maintenance-ip"
FILES:irma6-maintenance-ip = "${sysconfdir}/network/if-pre-up.d/eth0-pre-up-maintenance"
