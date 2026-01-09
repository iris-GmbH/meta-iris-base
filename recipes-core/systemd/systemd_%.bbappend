FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "\
    file://10-keep-eth0.conf \
    file://01-custom-journald.conf \
    file://99-watchdog.conf \
    file://clock-epoch \
"

FILES:${PN} += "\
    ${libdir}/clock-epoch \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network/99-default.link.d
    install -m 0644 ${WORKDIR}/10-keep-eth0.conf ${D}${sysconfdir}/systemd/network/99-default.link.d/

    install -D -m0644 ${WORKDIR}/01-custom-journald.conf ${D}${sysconfdir}/systemd/journald.conf.d/01-custom-journald.conf

    install -D -m0644 ${WORKDIR}/99-watchdog.conf ${D}${sysconfdir}/systemd/system.conf.d/99-watchdog.conf

    # default system start time is 09-03-2018 (1520596496 since epoch)
    install -D -m0644 ${WORKDIR}/clock-epoch ${D}${libdir}/
}
