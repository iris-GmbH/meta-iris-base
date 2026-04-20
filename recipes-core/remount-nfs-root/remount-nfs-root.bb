SUMMARY = "Remount NFS root as read-write"
DESCRIPTION = "Systemd oneshot service to remount NFS root read-write during early boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://remount-nfs-root.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "remount-nfs-root.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/remount-nfs-root.service ${D}${systemd_system_unitdir}/remount-nfs-root.service
}
