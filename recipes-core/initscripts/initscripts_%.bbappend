FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://save-rtc-loop.sh \
    file://factory-reset.sh \
    file://factory-reset-functions \
"

RDEPENDS_${PN}_append = "phytool"

do_install_append() {
	# Remove S06checkroot.sh symlink to avoid "ro" /
	# remounting when using nfs boot and expecting rw access
	# from prior mounting in the initramfs init script.
	update-rc.d -f -r ${D} checkroot.sh remove

	install -m 0755 ${WORKDIR}/save-rtc-loop.sh ${D}${sysconfdir}/init.d
	update-rc.d -r ${D} save-rtc-loop.sh start 45 S .

	install -m 0755 ${WORKDIR}/factory-reset.sh ${D}${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/factory-reset-functions ${D}${sysconfdir}/init.d
	update-rc.d -r ${D} factory-reset.sh start 18 5 .
}

