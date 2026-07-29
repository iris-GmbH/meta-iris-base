FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# self build ethosu firmware for reduced X mb RAM
SRC_URI:append:imx93-matrixup = " file://ethosu_firmware"

do_install:imx93-matrixup () {
    install -d ${D}${nonarch_base_libdir}/firmware
    install -m 0644 ${WORKDIR}/ethosu_firmware ${D}${nonarch_base_libdir}/firmware/ethosu_firmware
}
