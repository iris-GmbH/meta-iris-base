# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Small image capable of booting a device. The kernel includes \
the Minimal RAM-based Initial Root Filesystem (initramfs), which finds the \
first 'init' program more efficiently."

INITRAMFS_COMMON_PACKAGES = " \
			  irma-initrdscripts-init \
			  base-files \
			  udev \
			  base-passwd \
			  ${VIRTUAL-RUNTIME_base-utils} \
			  ${ROOTFS_BOOTSTRAP_INSTALL} \
"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit core-image

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

BAD_RECOMMENDATIONS += "busybox-syslog busybox-udhcpc"

PACKAGE_INSTALL = "${INITRAMFS_COMMON_PACKAGES}"
