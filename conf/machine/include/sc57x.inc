# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

MACHINEOVERRIDES =. "sc57x:"

MACHINE_EXTRA_RRECOMMENDS = " kernel-modules kernel-devicetree"

EXTRA_IMAGEDEPENDS += "u-boot"

include conf/machine/include/tune-cortexa5.inc
DEFAULTTUNE="cortexa5thf-neon"

IMAGE_FSTYPES += "tar.bz2 jffs2 jffs2.sum"
EXTRA_IMAGECMD_jffs2 = "--little-endian --pad=0x0 --pagesize=0x1000 --eraseblock=0x10000 --squash"

SERIAL_CONSOLE = "115200 ttySC0"

PREFERRED_PROVIDER_virtual/kernel ?= "linux-gen6"
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-adi"
PREFERRED_PROVIDER_u-boot = "u-boot-adi"

KERNEL_IMAGETYPE = "uImage-gzip"
KERNEL_IMAGE_SYMLINK = "uImage"
KERNEL_DEVICETREE ?= "sc573-gen6.dtb"
KERNEL_DEVICETREE_SYMLINK = "sc57x-gen6.dtb"
KERNEL_EXTRA_ARGS += "LOADADDR=${UBOOT_ENTRYPOINT}"

UBOOT_SUFFIX = "ldr"
UBOOT_MACHINE ?= "sc573-gen6_defconfig"
UBOOT_ENTRYPOINT = "0x82008000"
UBOOT_LOADADDRESS = "0x82000000"

IMAGE_BOOT_FILES ?= "u-boot.${UBOOT_SUFFIX}"

#Disable rtc in busybox
MACHINE_FEATURES_BACKFILL_CONSIDERED = "rtc"

BOARD ?= "sc573-gen6"

# ldconfig is used to rebuild the /etc/ld.so.cache when new libraries are introduced during runtime
# this is not needed and /etc/ld.so.cache is already populated by Yocto, disabling this saves ~250kB
DISTRO_FEATURES_remove += "ldconfig"

IMAGE_FEATURES_remove += "read-only-rootfs"
