FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://10-nfs-eth0.network \
    file://01-custom-journald.conf \
    file://10-disable-mdns.conf \
"

do_install:append() {
    install -D -m0644 ${WORKDIR}/10-nfs-eth0.network ${D}${sysconfdir}/systemd/network/10-nfs-eth0.network
    install -D -m0644 ${WORKDIR}/01-custom-journald.conf ${D}${sysconfdir}/systemd/journald.conf.d/01-custom-journald.conf
    install -D -m0644 ${WORKDIR}/10-disable-mdns.conf ${D}${sysconfdir}/systemd/resolved.conf.d/10-disable-mdns.conf
}

FILES:${PN}:append = " \
    ${sysconfdir}/systemd/network/ \
    ${sysconfdir}/systemd/journald.conf.d/ \
    ${sysconfdir}/systemd/resolved.conf.d/ \
"
