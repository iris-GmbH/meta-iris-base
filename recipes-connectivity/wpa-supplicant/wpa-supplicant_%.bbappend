FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0002-Add-iris-specific-checks-to-wpa-supplicant.sh.patch;patchdir=.. \
    file://0001-Enable-syslog-logging-in-wpa_supplicant.patch;patchdir=.. \
"
