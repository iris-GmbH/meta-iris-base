# recipe to patch avahi-core sources and to change the avahi-daemon.conf

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# fixes RDV-2762
# patch taken from https://github.com/lathiat/avahi/pull/115
# TODO: clean up patch, so that it is accepted into upstream. See comments in linked PR.
SRC_URI += "\
	file://0001-filter-denied-virtual-interfaces-when-adding-address.patch \
	file://avahi-daemon.conf \
	file://irma-provider.service \
	file://FindAvahi.cmake \
"

target_path = "/etc/avahi"

do_install:append() {
    if [ ! -d ${target_path} ]; then
		install -d ${D}/${target_path}
	fi
	
	#copy avahi-daemon.conf
	install -m 0755 ${WORKDIR}/avahi-daemon.conf ${D}/${target_path}

	#copy irma-provider.service
	install -m 0755 ${WORKDIR}/irma-provider.service ${D}/${target_path}/services

	install -d ${D}${datadir}/cmake/Modules
	install -m 644 ${WORKDIR}/FindAvahi.cmake ${D}${datadir}/cmake/Modules
}
