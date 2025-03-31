SRC_URI += " \
    file://50default \
    file://read_usedhcpoption42_script.sh \
    file://timeservice_dhcp_option_42.sh \
    file://ntp_query_status.sh \
    file://mdev.conf \
    file://fragments.cfg \
    file://busybox_watchdog.sh \
"

# R2 only fragments
SRC_URI:append:poky-iris-0602 = " file://fragments-R2.cfg"
SRC_URI:append:poky-iris-0501 = " file://fragments-R2.cfg"

# R2 only maintenance fragments
SRC_URI:append:poky-iris-0602:poky-iris-maintenance = " file://fragments-maintenance-R2.cfg"
SRC_URI:append:poky-iris-0501:poky-iris-maintenance = " file://fragments-maintenance-R2.cfg"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

FILES:${PN} += " \
    ${sysconfdir}/init.d/busybox_watchdog.sh \
    ${sysconfdir}/rc5.d/S01watchdog \
    ${sysconfdir}/udhcpc.d/50default\
    ${sysconfdir}/udhcpc.d/dhcp_option_42/read_usedhcpoption42_script.sh \
    ${sysconfdir}/udhcpc.d/dhcp_option_42/timeservice_dhcp_option_42.sh \
    ${bindir}/ntp_query_status.sh \
"


initd="${D}${sysconfdir}/init.d"
rc5d="${D}${sysconfdir}/rc5.d"
udhcp="${D}${sysconfdir}/udhcpc.d"
udhcpoption42="${udhcp}/dhcp_option_42"
ntpstatus="${D}${bindir}"

do_install:append() {
    install -d ${udhcp}
    install -d ${udhcpoption42}
    install -m 0755 ${WORKDIR}/50default ${udhcp}/
    install -m 0755 ${WORKDIR}/read_usedhcpoption42_script.sh ${udhcpoption42}/
    install -m 0755 ${WORKDIR}/timeservice_dhcp_option_42.sh ${udhcpoption42}/
}

do_install:append:poky-iris-0601() {
    install -d ${ntpstatus}
    install -m 0755 ${WORKDIR}/ntp_query_status.sh ${ntpstatus}/
}

do_install_shared() {
    install -d ${initd}
    install -d ${rc5d}

    #busybox's watchdog support
    install -m 0755 ${WORKDIR}/busybox_watchdog.sh ${initd}/
    ln -s -r ${initd}/busybox_watchdog.sh ${rc5d}/S01watchdog
}

do_install:append:poky-iris-0501() {
    do_install_shared
}

do_install:append:poky-iris-0602() {
    do_install_shared
}
