FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append_mx8mp = " file://dropbear_rsa_host_key \
	"

do_install_append_mx8mp () {
	install -d ${D}${sysconfdir}/dropbear
	install ${WORKDIR}/dropbear_rsa_host_key -m 0600 ${D}${sysconfdir}/dropbear/
}
