FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "\
    file://10-keep-eth0.conf \
    file://01-custom-journald.conf \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network/99-default.link.d
    install -m 0644 ${WORKDIR}/10-keep-eth0.conf ${D}${sysconfdir}/systemd/network/99-default.link.d/

    install -D -m0644 ${WORKDIR}/01-custom-journald.conf ${D}${sysconfdir}/systemd/journald.conf.d/01-custom-journald.conf
}
