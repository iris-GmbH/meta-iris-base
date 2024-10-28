# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

MACHINEOVERRIDES =. "sc57x:"

MACHINE_EXTRA_RRECOMMENDS = " kernel-modules kernel-devicetree"

EXTRA_IMAGEDEPENDS += "u-boot"

include conf/machine/include/arm/armv7a/tune-cortexa5.inc
DEFAULTTUNE="cortexa5thf-neon"

IMAGE_FSTYPES += "tar.bz2 jffs2"
EXTRA_IMAGECMD:jffs2 = "--little-endian --pad=0x0 --pagesize=0x1000 --eraseblock=0x10000 --squash"

SERIAL_CONSOLE = "115200 ttySC0"

PREFERRED_PROVIDER_virtual/kernel ?= "linux-gen6"
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-adi"
PREFERRED_PROVIDER_u-boot = "u-boot-adi"

KERNEL_IMAGETYPE = "uImage-gzip"
KERNEL_IMAGE_SYMLINK = "uImage"
KERNEL_DEVICETREE ?= "sc573-gen6.dtb"
KERNEL_DEVICETREE_SYMLINK = "sc57x-gen6.dtb"
KERNEL_EXTRA_ARGS += "LOADADDR=${UBOOT_ENTRYPOINT}"

OLDEST_KERNEL = "4.14"

UBOOT_SUFFIX = "ldr"
UBOOT_MACHINE ?= "sc573-gen6_defconfig"
UBOOT_ENTRYPOINT = "0x82008000"
UBOOT_LOADADDRESS = "0x82000000"

IMAGE_BOOT_FILES ?= "u-boot.${UBOOT_SUFFIX}"

BOARD ?= "sc573-gen6"
