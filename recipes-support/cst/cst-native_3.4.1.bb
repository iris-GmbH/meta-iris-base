require cst.inc

DESCRIPTION = "Code Signing Tool for NXP's High Assurance Boot with i.MX processors."

SRC_URI[sha256sum] = "17814909d0193f6c7dbb84bc4c51ecd47231a5571cbe9b32527d128bdb727b7d"

INSANE_SKIP:${PN} += " \
 already-stripped \
"

inherit native

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
