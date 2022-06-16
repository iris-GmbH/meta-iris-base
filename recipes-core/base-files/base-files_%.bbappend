FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://fstab"

# Create /mnt/ folders so the fstab can use it as mountpoint
dirs755_append_mx8mp = " /mnt/iris /mnt/keystore"
