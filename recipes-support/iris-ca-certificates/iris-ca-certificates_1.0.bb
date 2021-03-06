# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Provide iris ca certificates"
SECTION = "support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILES_${PN} = "${sysconfdir}/iris/ca-certificates"

do_install() {
    if [ ! -e "${SWUPDATE_CA_CERT}" ]; then
        bbfatal "Error: SWUPDATE_CA_CERT: ${SWUPDATE_CA_CERT} does not exist!"
    fi
    install -d ${D}${sysconfdir}/iris/ca-certificates
    install -m 0644 ${SWUPDATE_CA_CERT} ${D}${sysconfdir}/iris/ca-certificates/swupdate-ca.crt
}
