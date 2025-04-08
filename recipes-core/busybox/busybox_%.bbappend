# SPDX-License-Identifier: MIT
# Copyright (C) 2025 iris-GmbH infrared & intelligent sensors

# Use helper variable SRC_URI_EXTRA to add non-R1 fragments
SRC_URI_EXTRA = "file://fragments-R2.cfg"
SRC_URI_EXTRA:poky-iris-0601 = ""

SRC_URI:append = " \
    file://50default \
    file://60-add-eth0-alias \
    file://read_usedhcpoption42_script.sh \
    file://timeservice_dhcp_option_42.sh \
    file://ntp_query_status.sh \
    file://mdev.conf \
    file://fragments.cfg \
    file://busybox_watchdog.sh \
    ${SRC_URI_EXTRA} \
"

RDEPENDS:${PN}-udhcpc += "init-ifupdown"

# Use helper variable SRC_URI_MAINTENANCE to add non-R1 maintenance fragments
SRC_URI_MAINTENANCE = "file://fragments-maintenance-R2.cfg"
SRC_URI_MAINTENANCE:poky-iris-0601 = ""

SRC_URI:append:poky-iris-maintenance = " ${SRC_URI_MAINTENANCE}"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

FILES:${PN} += " \
    ${sysconfdir}/init.d/busybox_watchdog.sh \
    ${sysconfdir}/rc5.d/S01watchdog \
    ${sysconfdir}/udhcpc.d/50default \
    ${sysconfdir}/udhcpc.d/60-add-eth0-alias \
    ${sysconfdir}/udhcpc.d/dhcp_option_42/read_usedhcpoption42_script.sh \
    ${sysconfdir}/udhcpc.d/dhcp_option_42/timeservice_dhcp_option_42.sh \
    ${bindir}/ntp_query_status.sh \
"

initd="${D}${sysconfdir}/init.d"
rc5d="${D}${sysconfdir}/rc5.d"
udhcp="${D}${sysconfdir}/udhcpc.d"
udhcpoption42="${udhcp}/dhcp_option_42"
ntpstatus="${D}${bindir}"

do_iris_install_shared() {
    install -d ${udhcp}
    install -d ${udhcpoption42}
    install -m 0755 ${WORKDIR}/50default ${udhcp}/
    install -m 0755 ${WORKDIR}/60-add-eth0-alias ${udhcp}/
    install -m 0755 ${WORKDIR}/read_usedhcpoption42_script.sh ${udhcpoption42}/
    install -m 0755 ${WORKDIR}/timeservice_dhcp_option_42.sh ${udhcpoption42}/
}

do_iris_install() {
    do_iris_install_shared

    install -d ${initd}
    install -d ${rc5d}

    #busybox's watchdog support
    install -m 0755 ${WORKDIR}/busybox_watchdog.sh ${initd}/
    ln -s -r ${initd}/busybox_watchdog.sh ${rc5d}/S01watchdog
}

do_iris_install:poky-iris-0601() {
    do_iris_install_shared

    install -d ${ntpstatus}
    install -m 0755 ${WORKDIR}/ntp_query_status.sh ${ntpstatus}/
}

do_install:append() {
    do_iris_install
}
