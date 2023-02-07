FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:mx8mp-nxp-bsp = " file://dropbear_rsa_host_key \
	"

do_install:append:mx8mp-nxp-bsp () {
	install -d ${D}${sysconfdir}/dropbear
	install ${WORKDIR}/dropbear_rsa_host_key -m 0600 ${D}${sysconfdir}/dropbear/
}
