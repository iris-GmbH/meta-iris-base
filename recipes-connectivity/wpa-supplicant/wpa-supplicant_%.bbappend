FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0002-Add-iris-specific-checks-to-wpa-supplicant.sh.patch;patchdir=.. \
"

SRC_URI:append:use-irma6r2-bsp = " file://0001-Enable-syslog-logging-in-wpa_supplicant.patch;patchdir=.."
SRC_URI:append:use-irma-matrix-bsp = " file://0001-Enable-syslog-logging-in-wpa_supplicant_matrix.patch;patchdir=.."
