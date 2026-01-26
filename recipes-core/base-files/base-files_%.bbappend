FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://fstab"
SRC_URI:append:systemd = " file://fstab-systemd"

# Create /mnt/ folders so the fstab can use it as mountpoint
dirs755:append:mx8mp-nxp-bsp = " /mnt/keystore /mnt/iris /mnt/datastore"
dirs755:append:mx93-nxp-bsp = " /mnt/keystore /mnt/iris /mnt/datastore /mnt/devicedata"

do_install:append:systemd () {
    if [ -f "${WORKDIR}/fstab-systemd" ]; then
        install -m 0644 "${WORKDIR}/fstab-systemd" "${D}${sysconfdir}/fstab"
    fi
}
