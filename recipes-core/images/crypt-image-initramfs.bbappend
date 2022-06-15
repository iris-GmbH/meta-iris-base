# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

INITRAMFS_COMMON_PACKAGES = " \
			  initramfs-init \
			  base-files \
			  udev \
			  base-passwd \
			  lvm2 \
			  ${VIRTUAL-RUNTIME_base-utils} \
			  ${ROOTFS_BOOTSTRAP_INSTALL} \
"
# IRMA6R2 SoC specific packages (not included in qemu)
INITRAMFS_COMMON_PACKAGES_append_mx8mp = " \
   keyctl-caam \
   util-linux-blockdev \
   keyutils \
"

PACKAGE_INSTALL = "${INITRAMFS_COMMON_PACKAGES}"
