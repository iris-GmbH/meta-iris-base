FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://10-nfs-eth0.network \
    file://01-custom-journald.conf \
"

do_install:append() {
    install -D -m0644 ${WORKDIR}/10-nfs-eth0.network ${D}${sysconfdir}/systemd/network/10-nfs-eth0.network
    install -D -m0644 ${WORKDIR}/01-custom-journald.conf ${D}${sysconfdir}/systemd/journald.conf.d/01-custom-journald.conf
}

FILES:${PN}:append = " \
    ${sysconfdir}/systemd/network/ \
    ${sysconfdir}/systemd/journald.conf.d/ \
"
