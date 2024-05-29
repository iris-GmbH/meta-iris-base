DESCRIPTION = "Code Signing Tool for NXP's High Assurance Boot with i.MX processors."
AUTHOR = "NXP"
HOMEPAGE = "http://www.nxp.com"
LICENSE = "BSD-3-Clause & OpenSSL & hidapi"
LIC_FILES_CHKSUM = "file://${S}/LICENSE.bsd3;md5=1fbcd66ae51447aa94da10cbf6271530 \
                    file://${S}/LICENSE.openssl;md5=06698624268f7be8151210879bbcbcab \
                    file://${S}/LICENSE.hidapi;md5=e0ea014f523f64f0adb13409055ee59e"

INSANE_SKIP:${PN} += " \
 already-stripped \
"

inherit native

S = "${WORKDIR}/cst-${PV}"

do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
  install -d ${D}${bindir}
  install -m 0755 ${S}/${SRCDIR}/bin/cst ${D}${bindir}
  install -m 0755 ${S}/${SRCDIR}/bin/srktool ${D}${bindir}
  install -m 0755 ${S}/${SRCDIR}/bin/hab_log_parser ${D}${bindir}
}

COMPATIBLE_HOST = "(i686|x86_64).*-linux"
SRCDIR:x86-64 = "/linux64"
SRCDIR_i686 = "/linux32"
