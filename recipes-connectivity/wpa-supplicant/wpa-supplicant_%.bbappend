FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0002-Use-IRMA-wpa-supplicant-preparation-helper.patch;patchdir=.. \
    file://0001-Enable-syslog-logging-in-wpa_supplicant.patch;patchdir=.. \
    file://irma-wpa-supplicant-prepare \
    file://irma-wpa-supplicant.service \
"

SYSTEMD_SERVICE:${PN} = "irma-wpa-supplicant.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN}:append = " jq"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/irma-wpa-supplicant.service \
        ${D}${systemd_system_unitdir}/irma-wpa-supplicant.service

    install -d ${D}${libexecdir}
    install -m 0755 ${WORKDIR}/irma-wpa-supplicant-prepare \
        ${D}${libexecdir}/irma-wpa-supplicant-prepare
}
