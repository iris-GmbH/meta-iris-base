# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# set fixed srcrev for offline builds
SRCREV = "c372d6caddd5945952822e5a619493fdb74a6410"

UBOOT_BRANCH = "release/yocto-1.0.0"
INIT_PATH = "arch/arm/cpu/armv7/sc57x"

SRC_URI += " \
    file://0001-add-initial-gcc9-support.patch \
    file://0002-Add-target-to-generate-initial-environment.patch \
    file://0003-compiler-.h-sync-include-linux-compiler-.h-with-Linu.patch \
    file://0004-net-Use-packed-structures-for-networking.patch \
    file://0005-remove-duplicate-const-specifier.patch \
    file://0006-fix-while-loop-stop-condition-for-errors-on-the-i2c-.patch \
    file://0007-remove-warning-when-not-using-block-dev.patch \
    file://0008-remove-crosscompile-and-add-floating-point-cppflag.patch \
    file://0009-add-the-iris-boards.patch \
    file://0010-Add-iris-common-functions.patch \
    file://0011-changes-to-sc_adi_common.h.patch \
    file://0012-prettier-u-boot-version-string.patch \
    file://0013-add-IS25LP256D-support.patch \
    file://0014-this-commit-hackily-fixes-the-issues-with-double-pro.patch \
    file://0015-sf-bar-Clean-BA24-Bank-Address-Register-bit-after-re.patch \
    file://0016-mtd-spi-Enable-QE-bit-for-ISSI-flash-in-case-of-SFDP.patch \
    file://0017-use-mmap-for-flash-on-spi2-saves-1.6sec.patch \
    file://0018-add-support-for-MEM_AS4C64M16D3-and-RMII.patch \
    file://0019-add-support-for-micrel-phy-ksz8001-and-ksz8081.patch \
    file://0020-add-localversion-iris.patch \
    file://0021-remove-space-from-localversion-adi.patch \
"

# add the file containing the u-boot version string to the sysroot,
# so that we can consume it within other recipes.
FILES:${PN}-dev += "${datadir}/uboot.release"
do_install:append() {
    install -d ${D}/${datadir}
    install ${B}/include/config/uboot.release ${D}${datadir}/uboot.release
}

do_fixldr() {
    if [ "${TARGET_SYS}" != "arm-poky-linux-gnueabi" ]
    then
        # Layer "lnxdsp-adi-meta" (branch release/yocto-1.0.0) brings a pre-build LDR binary
        # Create symlink if libc is not provided by glibc/gnueabi
        cd "${WORKDIR}" && ln -sf arm-poky-linux-gnueabi-ldr "${TARGET_SYS}-ldr"
    fi
}

addtask do_fixldr after do_unpack before do_configure
