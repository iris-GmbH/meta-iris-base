SUMMARY = "Set permissions for /mnt/iris"
DESCRIPTION = "Correct permissions for certificates and keys"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://mnt-iris-permissions.sh \
    file://set-mount-permissions.init \
    file://set-mount-permissions.service \
"

FILES:${PN} += " \
    ${bindir}/mnt-iris-permissions.sh \
"

inherit systemd
inherit update-rc.d

SYSTEMD_SERVICE:${PN} = "set-mount-permissions.service"

INITSCRIPT_NAME = "set-mount-permissions"
INITSCRIPT_PARAMS = "start 40 S ."

do_install() {
    # Install the main script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mnt-iris-permissions.sh ${D}${bindir}/mnt-iris-permissions.sh

    # Install systemd service unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/set-mount-permissions.service ${D}${systemd_system_unitdir}/set-mount-permissions.service

    # Install sysvinit script
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/set-mount-permissions.init ${D}${sysconfdir}/init.d/set-mount-permissions
}
