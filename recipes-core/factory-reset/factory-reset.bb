SUMMARY = "Irma Factory Reset"
DESCRIPTION = "Eth-Phy short detector and configuration reset"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += " \
    file://factory-reset.sh \
    file://factory-reset-functions \
    file://factory-reset.init \
    file://factory-reset.service \
"

FILES:${PN} += " \
    ${datadir}/factory-reset/factory-reset-functions \
    ${bindir}/factory-reset.sh \
"

RDEPENDS:${PN} += "phytool"

inherit systemd
inherit update-rc.d

SYSTEMD_SERVICE:${PN} = "factory-reset.service"

INITSCRIPT_NAME = "factory-reset"
INITSCRIPT_PARAMS = "start 8 5 ."

do_install:append () {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/factory-reset.init ${D}${sysconfdir}/init.d/factory-reset

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/factory-reset.service ${D}${systemd_system_unitdir}/factory-reset.service

    install -D -m 0755 ${WORKDIR}/factory-reset-functions ${D}${datadir}/factory-reset/factory-reset-functions
    install -D -m 0755 ${WORKDIR}/factory-reset.sh ${D}${bindir}/factory-reset.sh
}
