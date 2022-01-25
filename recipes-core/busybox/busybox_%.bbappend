SRC_URI += "file://fragment.cfg"
SRC_URI += "file://arp.cfg"
SRC_URI += "file://ntpd.cfg"
SRC_URI += "file://mdev.conf"

FILESEXTRAPATHS_prepend := "${THISDIR}/busybox:"

