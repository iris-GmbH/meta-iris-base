SRC_URI += " \
			file://50default \
			file://read_usedhcpoption42_script.sh \
			file://timeservice_dhcp_option_42.sh \
			file://mdev.conf \
			file://fragments.cfg \
			file://busybox_watchdog.sh \
"

# R2 only fragments
SRC_URI += "${@'file://fragments-R2.cfg' if d.getVar('IRMA6_RELEASE') != 1 else ''}"

# R2 only maintenance fragments
SRC_URI += "${@'file://fragments-maintenance-R2.cfg' if d.getVar('DISTRO', True) == 'poky-iris-maintenance' and d.getVar('IRMA6_RELEASE') != 1 else ''}"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

FILES:${PN} += "${sysconfdir}/init.d/busybox_watchdog.sh \
                ${sysconfdir}/rc5.d/S01watchdog \
                ${sysconfdir}/udhcpc.d/50default\
                ${sysconfdir}/udhcpc.d/dhcp_option_42/read_usedhcpoption42_script.sh \
                ${sysconfdir}/udhcpc.d/dhcp_option_42/timeservice_dhcp_option_42.sh \
               "


initd="${D}${sysconfdir}/init.d"
rc5d="${D}${sysconfdir}/rc5.d"
udhcp="${D}${sysconfdir}/udhcpc.d"
udhcpoption42="${udhcp}/dhcp_option_42"

do_install:append() {
	install -d ${udhcp}
	install -d ${udhcpoption42}
	install -m 0755 ${WORKDIR}/50default ${udhcp}/
	install -m 0755 ${WORKDIR}/read_usedhcpoption42_script.sh ${udhcpoption42}/
	install -m 0755 ${WORKDIR}/timeservice_dhcp_option_42.sh ${udhcpoption42}/
    if [ "${IRMA6_RELEASE}" -ne 1 ]
    then
        install -d ${initd}
        install -d ${rc5d}
        
        #busybox's watchdog support
        install -m 0755 ${WORKDIR}/busybox_watchdog.sh ${initd}/
        ln -s -r ${initd}/busybox_watchdog.sh ${rc5d}/S01watchdog
    fi
}

# Override busybox.inc - start mdev init script at rcS and rc5
INITSCRIPT_PARAMS:${PN}-mdev = "start 04 S 5 ."

