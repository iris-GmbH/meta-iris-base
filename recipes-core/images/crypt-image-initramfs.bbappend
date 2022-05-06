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

PACKAGE_INSTALL = "${INITRAMFS_COMMON_PACKAGES}"
