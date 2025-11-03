FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://save-rtc-loop.sh \
    file://factory-reset.sh \
    file://factory-reset-functions \
    file://factory-reset.init \
    file://timestamp \
    file://set-hostname.sh \
    file://set-mount-permissions.sh \
"

SRC_URI:append:sc57x = " \
    file://0001-initscripts-sysfs.sh-make-dir-dev-shm.patch \
    file://mount-alternative-partition.sh \
"

RDEPENDS:${PN}:append = " phytool"

FILES:${PN} += " \
    ${datadir}/factory-reset/factory-reset-functions \
    ${bindir}/factory-reset.sh \
"

FILES:${PN}:append:sc57x = " \
    ${sysconfdir}/init.d/mount-alternative-partition.sh \
"

do_install:append () {
    # Remove S06checkroot.sh symlink to avoid "ro" /
    # remounting when using nfs boot and expecting rw access
    # from prior mounting in the initramfs init script.
    update-rc.d -f -r ${D} checkroot.sh remove

    install -m 0755 ${WORKDIR}/save-rtc-loop.sh ${D}${sysconfdir}/init.d
    update-rc.d -r ${D} save-rtc-loop.sh start 45 S .

    install -D -m 0755 ${WORKDIR}/factory-reset-functions ${D}${datadir}/factory-reset/factory-reset-functions
    install -D -m 0755 ${WORKDIR}/factory-reset.sh ${D}${bindir}/factory-reset.sh
    install -D -m 0755 ${WORKDIR}/factory-reset.init ${D}${sysconfdir}/init.d/factory-reset
    update-rc.d -r ${D} factory-reset start 8 5 .

    install -D -m 0755 ${WORKDIR}/set-hostname.sh ${D}${sysconfdir}/init.d/set-hostname
    update-rc.d -r ${D} set-hostname start 40 S .
}

do_install_shared() {
    # Set timestamp file. /etc/default/timestamp will be sourced by the init-scripts
    install -D -m 0644 ${WORKDIR}/timestamp ${D}${sysconfdir}/default/timestamp

    install -m 0755 ${WORKDIR}/set-mount-permissions.sh ${D}${sysconfdir}/init.d
    update-rc.d -r ${D} set-mount-permissions.sh start 40 S .
}

do_install:append:sc57x() {
    install -m 0755 ${WORKDIR}/mount-alternative-partition.sh ${D}${sysconfdir}/init.d
    update-rc.d -r ${D} mount-alternative-partition.sh start 28 S .
}
