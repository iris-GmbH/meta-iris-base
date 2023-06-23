SUMMARY = "Go minifiers for web formats"
HOMEPAGE = "https://github.com/tdewolff/minify"
DESCRIPTION = "Minify is a minifier package written in Go. It \
provides HTML5, CSS3, JS, JSON, SVG and XML minifiers."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=558c0b97b087d8db8d5765b07c82e6f8"

SRC_URI = "https://github.com/tdewolff/minify/releases/download/v${PV}/${BPN}_linux_amd64.tar.gz"
SRC_URI[sha256sum] = "1a4fae9002e3d5cac558b31bb369ae32a68d97811c289bd72d2cd79178bf1356"
S = "${WORKDIR}"

inherit native

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/minify ${D}${bindir}/
}

INSANE_SKIP:${PN} = "already-stripped"
