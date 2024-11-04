require cst.inc

DESCRIPTION = "SRK Tool scripts for NXP's High Assurance Boot with i.MX processors."

SRC_URI[sha256sum] = "17814909d0193f6c7dbb84bc4c51ecd47231a5571cbe9b32527d128bdb727b7d"

FILES:${PN} += " \
    ${bindir}/createSRKFuses \
    ${bindir}/createSRKTable \
"

SRC_URI += " \
    file://0001-createSRKFuses-add-ecc-keys.patch;patchdir=${WORKDIR}/cst-${PV}/add-ons/hab_srktool_scripts \
"


B = "${S}/add-ons/hab_srktool_scripts"

RDEPENDS:${PN} += "bash perl"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/createSRKFuses ${D}${bindir}
    install -m 0755 ${B}/createSRKTable ${D}${bindir}
}
