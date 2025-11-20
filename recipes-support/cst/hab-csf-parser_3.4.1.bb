require cst.inc

DESCRIPTION = "CSF Parsing Tool for NXP's High Assurance Boot with i.MX processors."

SRC_URI[sha256sum] = "17814909d0193f6c7dbb84bc4c51ecd47231a5571cbe9b32527d128bdb727b7d"

FILES:${PN} += " \
    ${bindir}/csf_parser \
"

SRC_URI += " \
    file://0001-Makefile-Enable-cross-compilation.patch;patchdir=${WORKDIR}/cst-${PV}/add-ons/hab_csf_parser \
    file://0002-hab_csf_parser-improve-IVT-header-search.patch; \
"

B = "${S}/add-ons/hab_csf_parser"

TARGET_CC_ARCH += "${LDFLAGS}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/csf_parser ${D}${bindir}
}

BBCLASSEXTEND = "native"
