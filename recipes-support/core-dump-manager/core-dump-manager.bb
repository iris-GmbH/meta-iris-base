SUMMARY = "Core dump handler with compression and cleanup"
DESCRIPTION = "Automated core dump management with per-process cleanup and gzip compression"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://configure-core-dump.sh \
    file://core-dump-handler.sh \
    file://core-dump-utils.sh \
    file://configure-core-dump.service \
"

S = "${WORKDIR}"

# file lock with timeout support
RDEPENDS:${PN} = "util-linux-flock"

inherit update-rc.d systemd

INITSCRIPT_NAME = "configure-core-dump"
INITSCRIPT_PARAMS = "start 45 5 ."

SYSTEMD_SERVICE:${PN} = "configure-core-dump.service"

do_install() {
    install -d ${D}${datadir}/core-dump

    if ${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', 'true', 'false', d)}; then
        # Install the init script
        install -d ${D}${sysconfdir}/init.d
        install -m 755 ${WORKDIR}/configure-core-dump.sh ${D}${sysconfdir}/init.d/configure-core-dump
    else
        # in systemd install to /usr/share for compatibility mode
        install -m 755 ${WORKDIR}/configure-core-dump.sh ${D}${datadir}/core-dump/configure-core-dump

        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/configure-core-dump.service ${D}${systemd_system_unitdir}/configure-core-dump.service
    fi

    # Install the core dump handler
    install -m 755 ${WORKDIR}/core-dump-handler.sh ${D}${datadir}/core-dump/
    install -m 0644 ${WORKDIR}/core-dump-utils.sh ${D}${datadir}/core-dump/
}

FILES:${PN} = " \
    ${datadir}/core-dump/core-dump-handler.sh \
    ${datadir}/core-dump/core-dump-utils.sh \
    ${sysconfdir}/init.d/configure-core-dump \
"

FILES:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', '${datadir}/core-dump/configure-core-dump', '', d)}"
