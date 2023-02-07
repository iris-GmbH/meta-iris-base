FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append_mx8mp = " file://dropbear_rsa_host_key \
	"

do_install:append_mx8mp () {
	install -d ${D}${sysconfdir}/dropbear
	install ${WORKDIR}/dropbear_rsa_host_key -m 0600 ${D}${sysconfdir}/dropbear/
}
