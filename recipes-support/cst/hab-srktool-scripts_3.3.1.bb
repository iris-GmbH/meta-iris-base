DESCRIPTION = "SRK Tool scripts for NXP's High Assurance Boot with i.MX processors."
AUTHOR = "NXP"
HOMEPAGE = "http://www.nxp.com"
LICENSE = "CLOSED"

FILES:${PN} += " \
    ${bindir}/createSRKFuses \
    ${bindir}/createSRKTable \
    "

SRC_URI = "https://iris-devops-imx-cst-public-693612562064.s3.eu-central-1.amazonaws.com/cst-${PV}.tgz \
    file://0001-createSRKFuses-add-ecc-keys.patch;patchdir=${WORKDIR}/cst-${PV}/code/hab_srktool_scripts \
"
SRC_URI[sha256sum] = "1efdddda50cf36bc1e48d78a9601ba33db0cc2203ff1086c4b373f94b9366464"


S = "${WORKDIR}/cst-${PV}/code/hab_srktool_scripts"
RDEPENDS:${PN} += "bash perl"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/createSRKFuses ${D}${bindir}
    install -m 0755 ${S}/createSRKTable ${D}${bindir}
}
