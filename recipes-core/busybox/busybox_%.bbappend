SRC_URI += "file://fragment.cfg"
SRC_URI += "file://arp.cfg"
SRC_URI += "file://ntpd.cfg"
SRC_URI += "file://mdev.conf"
SRC_URI += "${@'file://enable_watchdog.cfg file://devmem.cfg' if d.getVar('IRMA6_RELEASE') != 1 else ''}"
SRC_URI += "file://busybox_watchdog.sh"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

FILES_${PN} += "${sysconfdir}/init.d/busybox_watchdog.sh \
                ${sysconfdir}/rc5.d/S01watchdog \
               "


initd="${D}${sysconfdir}/init.d"
rc5d="${D}${sysconfdir}/rc5.d"

do_install_append() {
    if [ "${IRMA6_RELEASE}" -ne 1 ]
    then
        install -d ${initd}
        install -d ${rc5d}
        
        #busybox's watchdog support
        install -m 0755 ${WORKDIR}/busybox_watchdog.sh ${initd}/
        ln -s -r ${initd}/busybox_watchdog.sh ${rc5d}/S01watchdog
    fi
}   

