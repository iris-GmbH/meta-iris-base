
# omit MOUNT_OPT, to not setup the rootfs read-only
mount -t nfs "${NFSPATH}" ${ROOT_MNT}
CMDLINE=""
