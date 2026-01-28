FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}${@bb.utils.contains('DISTRO_FEATURES', 'systemd', '-systemd', '', d)}:"

SRC_URI += "file://fstab"

# Create /mnt/ folders so the fstab can use it as mountpoint
dirs755:append:mx8mp-nxp-bsp = " /mnt/keystore /mnt/iris /mnt/datastore"
dirs755:append:mx93-nxp-bsp = " /mnt/keystore /mnt/iris /mnt/datastore /mnt/devicedata"
