FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://save-rtc-loop.sh \
    file://timestamp \
"

SRC_URI:append:sc57x = " \
    file://0001-initscripts-sysfs.sh-make-dir-dev-shm.patch \
    file://mount-alternative-partition.sh \
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
}

do_install_shared() {
    # Set timestamp file. /etc/default/timestamp will be sourced by the init-scripts
    install -D -m 0644 ${WORKDIR}/timestamp ${D}${sysconfdir}/default/timestamp
}

do_install:append:sc57x() {
    install -m 0755 ${WORKDIR}/mount-alternative-partition.sh ${D}${sysconfdir}/init.d
    update-rc.d -r ${D} mount-alternative-partition.sh start 28 S .
}
