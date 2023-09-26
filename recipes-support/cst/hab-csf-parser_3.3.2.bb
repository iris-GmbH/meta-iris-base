DESCRIPTION = "CSF Parsing Tool for NXP's High Assurance Boot with i.MX processors."
AUTHOR = "NXP"
HOMEPAGE = "http://www.nxp.com"
LICENSE = "BSD-3-Clause & OpenSSL & hidapi"
LIC_FILES_CHKSUM = "file://${S}/LICENSE.bsd3;md5=1fbcd66ae51447aa94da10cbf6271530 \
                    file://${S}/LICENSE.openssl;md5=06698624268f7be8151210879bbcbcab \
                    file://${S}/LICENSE.hidapi;md5=e0ea014f523f64f0adb13409055ee59e"

FILES:${PN} += "${bindir}/csf_parser"

SRC_URI = "https://iris-devops-imx-cst-public-693612562064.s3.eu-central-1.amazonaws.com/cst-${PV}.tgz \
    file://0001-Makefile-Enable-cross-compilation.patch;patchdir=${WORKDIR}/cst-${PV}/code/hab_csf_parser \
"
SRC_URI[sha256sum] = "517b11dca181e8c438a6249f56f0a13a0eb251b30e690760be3bf6191ee06c68"

S = "${WORKDIR}/cst-${PV}"
B = "${S}/code/hab_csf_parser"

TARGET_CC_ARCH += "${LDFLAGS}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/csf_parser ${D}${bindir}
}
