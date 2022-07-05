# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

CERT_TARGET_DIR = "${D}${datadir}/ca-certificates"

do_install:append() {
    if [ ! -e "${SWUPDATE_CMS_CERT}" ] ; then
        bberror "Error: SWUPDATE_CMS_CERT: ${SWUPDATE_CMS_CERT} does not exist!"
    fi
    install -d ${CERT_TARGET_DIR}/swupdate
    install -m 0755 ${SWUPDATE_CMS_CERT} ${CERT_TARGET_DIR}/swupdate/sign.crt
}
