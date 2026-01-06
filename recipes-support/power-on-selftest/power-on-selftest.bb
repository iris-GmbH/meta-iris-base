SUMMARY = "Power-On Self Test startup script"
DESCRIPTION = "Test the firmware after an update and reset uboot variables"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = " \
    file://power-on-selftest.sh \
    file://power-on-selftest.service \
    file://power-on-selftest.init \
"

FILES:${PN} += " \
    ${datadir}/iris/power-on-selftest.sh \
    ${sysconfdir}/init.d/power-on-selftest \
    ${systemd_system_unitdir}/power-on-selftest.service \
"

S = "${WORKDIR}"

RDEPENDS:${PN} += " \
    rsync \
    procps \
"

inherit update-rc.d systemd

INITSCRIPT_NAME = "power-on-selftest"
INITSCRIPT_PARAMS = "start 93 5 ."

SYSTEMD_SERVICE:${PN} = "power-on-selftest.service"

do_install() {
    # Install the main script
    install -d ${D}${datadir}/iris
    install -m 0755 ${WORKDIR}/power-on-selftest.sh ${D}${datadir}/iris/power-on-selftest.sh

    # Install SysVinit script, automatically removed on systemd
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/power-on-selftest.init ${D}${sysconfdir}/init.d/power-on-selftest

    # Install systemd unit file, automatically removed on sysvinit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/power-on-selftest.service ${D}${systemd_system_unitdir}/power-on-selftest.service
}
