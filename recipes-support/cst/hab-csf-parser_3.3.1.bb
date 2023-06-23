DESCRIPTION = "CSF Parsing Tool for NXP's High Assurance Boot with i.MX processors."
AUTHOR = "NXP"
HOMEPAGE = "http://www.nxp.com"
LICENSE = "CLOSED"

FILES:${PN} += "${bindir}/csf_parser"

SRC_URI = "https://iris-devops-imx-cst-public-693612562064.s3.eu-central-1.amazonaws.com/cst-${PV}.tgz \
    file://0001-Makefile-Enable-cross-compilation.patch;patchdir=${WORKDIR}/cst-${PV}/code/hab_csf_parser \
"
SRC_URI[sha256sum] = "1efdddda50cf36bc1e48d78a9601ba33db0cc2203ff1086c4b373f94b9366464"

S = "${WORKDIR}/cst-${PV}/code/hab_csf_parser"

TARGET_CC_ARCH += "${LDFLAGS}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/csf_parser ${D}${bindir}
}
