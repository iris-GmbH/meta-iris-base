FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://fstab"

# Create /mnt/ folders so the fstab can use it as mountpoint
dirs755:append:mx8mp = " /mnt/keystore /mnt/iris"
