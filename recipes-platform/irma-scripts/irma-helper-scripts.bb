DESCRIPTION = "Misc IRMA Helper scripts"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = " \
"

SRC_URI:append:poky-iris-0501 = " \
    file://srk_hash.sh \
"

DIR_IRIS_SCRIPTS = "${datadir}/iris"

do_install() {
    install -d ${D}${bindir}/
    install -d ${D}${DIR_IRIS_SCRIPTS}
}

do_install:append:poky-iris-0501() {
    install -m 0755 ${WORKDIR}/srk_hash.sh ${D}${DIR_IRIS_SCRIPTS}/
    ln -sf ${DIR_IRIS_SCRIPTS}/srk_hash.sh ${D}${bindir}/srk_hash
}

PACKAGES = "${PN}"
FILES:${PN}:append:poky-iris-0501 = "\
    ${DIR_IRIS_SCRIPTS}/* \
    ${bindir}/srk_hash \
"
