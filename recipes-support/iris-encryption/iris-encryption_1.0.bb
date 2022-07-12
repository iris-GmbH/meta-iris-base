# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Provide iris encryption key's"
SECTION = "support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILES_${PN} = "${sysconfdir}/iris/swupdate"

do_install() {
    if [ ! -e "${SWUPDATE_AES_FILE}" ]; then
        bbfatal "SWUPDATE_AES_FILE=$SWUPDATE_AES_FILE does not exist!"
    fi
    key=`cat ${SWUPDATE_AES_FILE} | grep ^key | cut -d '=' -f 2`
    iv=`cat ${SWUPDATE_AES_FILE} | grep ^iv | cut -d '=' -f 2`
    if [ -z "${key}" ] || [ -z "${iv}" ];then
        bbfatal "SWUPDATE_AES_FILE=$SWUPDATE_AES_FILE does not contain valid keys"
    fi
    install -d ${D}${sysconfdir}/iris/swupdate
    echo "${key} ${iv}" > ${D}${sysconfdir}/iris/swupdate/encryption.key
}
