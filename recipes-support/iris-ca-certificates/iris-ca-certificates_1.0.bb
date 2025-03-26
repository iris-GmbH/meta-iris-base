# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Provide iris ca certificates"
SECTION = "support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILES:${PN} = "${sysconfdir}/iris/ca-certificates"

install_download_crt() {
    install -d ${D}${sysconfdir}/iris/ca-certificates
    if [ ! -e "${DOWNLOAD_CRT}" ]; then
        bbfatal "Error: DOWNLOAD_CRT: ${DOWNLOAD_CRT} does not exist!"
    fi
    install -m 0644 ${DOWNLOAD_CRT} ${D}${sysconfdir}/iris/ca-certificates/download.crt
}

install_swupdate_crt() {
    install -d ${D}${sysconfdir}/iris/ca-certificates
    if [ ! -e "${SWUPDATE_CA_CERT}" ]; then
        bbfatal "Error: SWUPDATE_CA_CERT: ${SWUPDATE_CA_CERT} does not exist!"
    fi
    install -m 0644 ${SWUPDATE_CA_CERT} ${D}${sysconfdir}/iris/ca-certificates/swupdate-ca.crt
}

do_install() {
    install_swupdate_crt
    install_download_crt
}

do_install:poky-iris-0601() {
    install_download_crt
}
