FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
PACKAGECONFIG:remove = "programs"
ALTERNATIVE:${PN}-programs = ""

SRC_URI += " \
    file://FindMbedTLS.cmake \
"

SRC_URI:append:poky-iris-0601 = " \
    file://mbedtls-0601-config.h \
"

EXTRA_OECMAKE:append:poky-iris-0601 = "\
    -DMBEDTLS_CONFIG_FILE=${WORKDIR}/mbedtls-0601-config.h \
"

do_install:append() {
    install -d ${D}${datadir}/cmake/Modules
    install -m 0644 ${WORKDIR}/FindMbedTLS.cmake ${D}${datadir}/cmake/Modules/
}
