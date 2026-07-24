SUMMARY = "CPU Synthetic Load Simulator"
DESCRIPTION = "stress-ng wrapper for thermal type tests"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://cpu-load-simulator.sh \
"

FILES:${PN} = " \
    ${bindir}/cpu-load-simulator.sh \
"

RDEPENDS:${PN} = " \
    bash \
    stress-ng \
"

do_install() {   
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/cpu-load-simulator.sh ${D}${bindir}/cpu-load-simulator.sh
}
