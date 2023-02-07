# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Provide iris signing key's"
SECTION = "support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILES:${PN} = "${sysconfdir}/iris/signing"

do_install() {
    install -d ${D}${sysconfdir}/iris/signing
    install -m 0644 ${ROOTHASH_SIGNING_PUBLIC_KEY} ${D}${sysconfdir}/iris/signing/roothash-public-key.pem
}
