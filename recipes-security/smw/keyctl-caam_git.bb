# Copyright 2020 NXP

SUMMARY = "NXP i.MX CAAM Keyctl"
DESCRIPTION = "NXP i.MX keyctl tool to manage CAAM Keys"
SECTION = "base"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://COPYING;md5=8636bd68fc00cc6a3809b7b58b45f982"

SRCBRANCH = "master"
KEYCTL_CAAM_SRC ?= "git://source.codeaurora.org/external/imx/keyctl_caam.git;protocol=https"
SRC_URI = "${KEYCTL_CAAM_SRC};branch=${SRCBRANCH}"

SRCREV = "6b80882e3d5bc986a1f2f9512845170658ba9ea2"

S = "${WORKDIR}/git"

TARGET_CC_ARCH += "${LDFLAGS}"

# Adjust keyblob location - this is fixed and cannot be changed during runtime
EXTRA_OEMAKE = "KEYBLOB_LOCATION=/mnt/keystore/caam/"

do_install () {
    oe_runmake DESTDIR=${D} install
}

COMPATIBLE_MACHINE = "(imx-nxp-bsp)"
