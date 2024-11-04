AUTHOR = "NXP"
HOMEPAGE = "http://www.nxp.com"
LICENSE = "BSD-3-Clause & OpenSSL & hidapi"
LIC_FILES_CHKSUM = "file://${S}/LICENSE.bsd3;md5=14aba05f9fa6c25527297c8aac95fcf6 \
                    file://${S}/LICENSE.openssl;md5=3441526b1df5cc01d812c7dfc218cea6 \
                    file://${S}/LICENSE.hidapi;md5=e0ea014f523f64f0adb13409055ee59e"

SRC_URI = "https://iris-devops-imx-cst-public-693612562064.s3.eu-central-1.amazonaws.com/cst-${PV}.tgz"

S = "${WORKDIR}/cst-${PV}"
