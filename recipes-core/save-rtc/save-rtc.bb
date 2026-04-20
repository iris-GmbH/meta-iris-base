SUMMARY = "Save and restore system time to/from timestamp file"
DESCRIPTION = "Periodically saves system time to a persistent file and restores it on boot when RTC is unavailable or outdated"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://save-rtc-loop.sh \
    file://restore-timestamp.sh \
    file://save-timestamp.sh \
    file://timestamp \
    file://restore-timestamp.service \
    file://save-timestamp.service \
    file://save-timestamp.timer \
"

FILES_SYSTEMD = " \
    ${bindir}/restore-timestamp.sh \
    ${bindir}/save-timestamp.sh \
"

FILES_SYSVINIT = " \
    ${sysconfdir}/default/timestamp \
    ${sysconfdir}/init.d/save-rtc-loop \
"

FILES:${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', '${FILES_SYSTEMD}', '${FILES_SYSVINIT}', d)}"

inherit systemd update-rc.d

SYSTEMD_SERVICE:${PN} = "restore-timestamp.service save-timestamp.service save-timestamp.timer"

INITSCRIPT_NAME = "save-rtc-loop"
INITSCRIPT_PARAMS = "start 45 S ."

do_install() {   
    if ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${WORKDIR}/save-rtc-loop.sh ${D}${sysconfdir}/init.d/save-rtc-loop

        # Install custom timestamp file
        install -d ${D}${sysconfdir}/default
        install -m 0644 ${WORKDIR}/timestamp ${D}${sysconfdir}/default/timestamp
    else
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/restore-timestamp.sh ${D}${bindir}/restore-timestamp.sh
        install -m 0755 ${WORKDIR}/save-timestamp.sh ${D}${bindir}/save-timestamp.sh

        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/restore-timestamp.service ${D}${systemd_system_unitdir}/restore-timestamp.service
        install -m 0644 ${WORKDIR}/save-timestamp.service ${D}${systemd_system_unitdir}/save-timestamp.service
        install -m 0644 ${WORKDIR}/save-timestamp.timer ${D}${systemd_system_unitdir}/save-timestamp.timer
    fi
}
