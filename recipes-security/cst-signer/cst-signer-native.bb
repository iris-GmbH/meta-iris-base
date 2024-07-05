SUMMARY = "CST Signer"
DESCRIPTION = "Image signing automation tool using CST"

# https://github.com/nxp-imx-support/meta-nxp-security-reference-design/blob/mickledore-6.1.55-2.2.0/meta-secure-boot/recipes-secure-boot/cst-signer/cst-signer.bb

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=b234ee4d69f5fce4486a80fdaf4a4263"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit native

S = "${WORKDIR}/git"

SRC_URI = " \
    ${CST_SIGNER};branch=${SRCBRANCH} \
    file://0001-Allow-different-cst-executable-and-key-path.patch \
"
CST_SIGNER ?= "git://github.com/nxp-imx-support/nxp-cst-signer.git;protocol=https"
SRCBRANCH = "master"
SRCREV = "de6d62632e55da6a27a5f223782d88d1ceb7821c"

do_install() {
  install -d ${D}${bindir}
  install -m 0755 ${S}/cst_signer ${D}${bindir}
}

COMPATIBLE_HOST = "(i686|x86_64).*-linux"
SRCDIR:x86-64 = "/linux64"
SRCDIR:i686 = "/linux32"
