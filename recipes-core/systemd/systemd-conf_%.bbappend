FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://10-nfs-eth0.network"

do_install:append() {
    install -D -m0644 ${WORKDIR}/10-nfs-eth0.network ${D}${sysconfdir}/systemd/network/10-nfs-eth0.network
}

FILES:${PN}:append = " ${sysconfdir}/systemd/network/"
