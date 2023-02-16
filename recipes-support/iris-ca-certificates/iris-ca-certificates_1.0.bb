# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Provide iris ca certificates"
SECTION = "support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILES_${PN} = "${sysconfdir}/iris/ca-certificates"

# Release 1 is limited to a subset
do_install_sc57x () {
    install -d ${D}${sysconfdir}/iris/ca-certificates
    if [ ! -e "${DOWNLOAD_SNAKEOIL_CRT}" ]; then
        bbfatal "Error: DOWNLOAD_SNAKEOIL_CRT: ${DOWNLOAD_SNAKEOIL_CRT} does not exist!"
    fi
    install -m 0644 ${DOWNLOAD_SNAKEOIL_CRT} ${D}${sysconfdir}/iris/ca-certificates/download.crt
}

do_install() {
    install -d ${D}${sysconfdir}/iris/ca-certificates

    if [ ! -e "${SWUPDATE_CA_CERT}" ]; then
        bbfatal "Error: SWUPDATE_CA_CERT: ${SWUPDATE_CA_CERT} does not exist!"
    fi
    install -m 0644 ${SWUPDATE_CA_CERT} ${D}${sysconfdir}/iris/ca-certificates/swupdate-ca.crt

    if [ ! -e "${DOWNLOAD_SNAKEOIL_CRT}" ]; then
        bbfatal "Error: DOWNLOAD_SNAKEOIL_CRT: ${DOWNLOAD_SNAKEOIL_CRT} does not exist!"
    fi
    install -m 0644 ${DOWNLOAD_SNAKEOIL_CRT} ${D}${sysconfdir}/iris/ca-certificates/download.crt
}
