SUMMARY = "Script for generating sensor identity certificate requests"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE;md5=857c3dd409701c6b384f78b478c91948"

SRC_URI += "file://create_identity_cert.sh"
SRC_URI += "file://sensor_cert.cnf"
SRC_URI += "file://LICENSE"

do_install() {
    install -m 0755 "${WORKDIR}/create_identity_cert.sh" "${D}/usr/local/bin/create_identity_cert.sh"
    install -m 0644 "${WORKDIR}/sensor_cert.cnf" "${D}/etc/openssl/sensor_cert.cnf"
}
FILES_${PN} += "/usr/local/bin/create_identity_cert.sh"
FILES_${PN} += "/etc/openssl/sensor_cert.cnf"
RDEPENDS_${PN} += "busybox openssl bash"
