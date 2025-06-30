SUMMARY = "Core dump handler with compression and cleanup"
DESCRIPTION = "Automated core dump management with per-process cleanup and gzip compression"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://configure-core-dump.sh \
    file://core-dump-handler.sh \
    file://core-dump-utils.sh \
"

S = "${WORKDIR}"

# file lock with timeout support
RDEPENDS:${PN} = "util-linux-flock"

inherit update-rc.d

INITSCRIPT_NAME = "configure-core-dump"
INITSCRIPT_PARAMS = "defaults 45"

do_install() {
    # Install the init script
    install -d ${D}${sysconfdir}/init.d
    install -m 755 ${WORKDIR}/configure-core-dump.sh ${D}${sysconfdir}/init.d/configure-core-dump

    # Install the core dump handler
    install -d ${D}${datadir}/core-dump
    install -m 755 ${WORKDIR}/core-dump-handler.sh ${D}${datadir}/core-dump/
    install -m 0644 ${WORKDIR}/core-dump-utils.sh ${D}${datadir}/core-dump/
}



FILES:${PN} = " \
    ${sysconfdir}/init.d/configure-core-dump \
    ${datadir}/core-dump/core-dump-handler.sh \
    ${datadir}/core-dump/core-dump-utils.sh \
"
