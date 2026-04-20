SUMMARY = "Set custom hostname"
DESCRIPTION = "Set mac address based hostname"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://set-hostname.sh \
    file://set-hostname.init \
    file://set-hostname.service \
"

FILES:${PN} += " \
    ${bindir}/set-hostname.sh \
"

inherit systemd
inherit update-rc.d

SYSTEMD_SERVICE:${PN} = "set-hostname.service"

INITSCRIPT_NAME = "set-hostname"
INITSCRIPT_PARAMS = "start 40 S ."

do_install() {
    # Install the main script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/set-hostname.sh ${D}${bindir}/set-hostname.sh

    # Install systemd service unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/set-hostname.service ${D}${systemd_system_unitdir}/set-hostname.service

    # Install sysvinit script
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/set-hostname.init ${D}${sysconfdir}/init.d/set-hostname
}
