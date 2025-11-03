SUMMARY = "Log location manager"
DESCRIPTION = "Switch log location based on persistent or volatile log configuration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://switch-log-location.sh \
    file://switch-log-location-init \
    file://switch-log-location.service \
"

FILES:${PN} += " \
    ${bindir}/switch-log-location.sh \
"

inherit systemd
inherit update-rc.d

# Note 1: /var/volatile/log is created and mounted in the initramfs
# Note 2: switch-log-location.sh should first be called after all other
#         devices are mounted (S03mountall.sh)

SYSTEMD_SERVICE:${PN} = "switch-log-location.service"
SYSTEMD_AUTO_ENABLE = "enable"

INITSCRIPT_NAME = "switch-log-location"
INITSCRIPT_PARAMS = "start 4 S ."

do_install() {
    # Install the main script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/switch-log-location.sh ${D}${bindir}/
    
    # Install systemd service unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/switch-log-location.service ${D}${systemd_system_unitdir}/
    
    # Install sysvinit script
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/switch-log-location-init ${D}${sysconfdir}/init.d/switch-log-location
}
