# SPDX-License-Identifier: MIT
# Copyright (C) 2025 iris-GmbH infrared & intelligent sensors

inherit systemd
SYSTEMD_SERVICE:${PN} = "irma-network-config.service"

SRC_URI += "file://irma-network-config.service"

FILES:${PN} += " \
    ${systemd_system_unitdir}/irma-network-config.service \
"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/irma-network-config.service ${D}${systemd_system_unitdir}/irma-network-config.service
}
