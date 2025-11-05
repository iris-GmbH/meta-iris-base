FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

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
}

do_install:append:sc57x() {
    install -m 0755 ${WORKDIR}/mount-alternative-partition.sh ${D}${sysconfdir}/init.d
    update-rc.d -r ${D} mount-alternative-partition.sh start 28 S .
}
