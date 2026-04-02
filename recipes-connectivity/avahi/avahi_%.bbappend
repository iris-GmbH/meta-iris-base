# recipe to patch avahi-core sources and to change the avahi-daemon.conf

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI_EXTRA = "file://0001-APC-7307-Add-custom-mount-point-due-to-RO-FS.patch"
SRC_URI_EXTRA:poky-iris-0601 = ""

# fixes RDV-2762
# patch taken from https://github.com/lathiat/avahi/pull/115
# TODO: clean up patch, so that it is accepted into upstream. See comments in linked PR.
SRC_URI += "\
	file://0001-filter-denied-virtual-interfaces-when-adding-address.patch \
	file://avahi-daemon.conf \
	file://irma-provider.service \
	file://avahi-services-setup.sh \
	file://avahi-services-setup.service \
	file://etc-avahi-services.mount \
	file://avahi-daemon-iris.conf \
	file://FindAvahi.cmake \
	${SRC_URI_EXTRA} \
"

target_path = "/etc/avahi"

FILES:avahi-daemon += " \
	${bindir}/avahi-services-setup.sh \
	${datadir}/avahi/irma-provider.service \
	${systemd_system_unitdir}/avahi-services-setup.service \
	${systemd_system_unitdir}/etc-avahi-services.mount \
	${systemd_system_unitdir}/avahi-daemon.service.d/iris.conf \
"

do_install:append() {
    if [ ! -d ${target_path} ]; then
		install -d ${D}/${target_path}
	fi
	
	#copy avahi-daemon.conf
	install -m 0644 ${WORKDIR}/avahi-daemon.conf ${D}/${target_path}

	if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
		install -d ${D}${bindir}
		install -m 0755 ${WORKDIR}/avahi-services-setup.sh ${D}${bindir}/avahi-services-setup.sh

		install -d ${D}${datadir}/avahi
		install -m 0644 ${WORKDIR}/irma-provider.service ${D}${datadir}/avahi/irma-provider.service

		install -d ${D}${systemd_system_unitdir}
		install -m 0644 ${WORKDIR}/avahi-services-setup.service ${D}${systemd_system_unitdir}/avahi-services-setup.service
		install -m 0644 ${WORKDIR}/etc-avahi-services.mount ${D}${systemd_system_unitdir}/etc-avahi-services.mount

		install -d ${D}${systemd_system_unitdir}/avahi-daemon.service.d
		install -m 0644 ${WORKDIR}/avahi-daemon-iris.conf ${D}${systemd_system_unitdir}/avahi-daemon.service.d/iris.conf

		install -d ${D}${sysconfdir}/avahi/services
	else
		install -d ${D}/${target_path}/services
		install -m 0644 ${WORKDIR}/irma-provider.service ${D}/${target_path}/services
	fi

	install -d ${D}${datadir}/cmake/Modules
	install -m 644 ${WORKDIR}/FindAvahi.cmake ${D}${datadir}/cmake/Modules
}

# Override useradd/groupadd parameters to use fixed UIDs/GIDs
GROUPADD_PARAM:avahi-daemon = "--system --gid 120 avahi"
USERADD_PARAM:avahi-daemon = "--system --home /run/avahi-daemon \
                              --no-create-home --shell /bin/false \
                              --gid 120 --uid 120 avahi"
