# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

# This file was derived from the linux-yocto-custom.bb recipe in
# oe-core.
#
# linux-gen6.bb:
#
#   A yocto-bsp-generated kernel recipe that uses the linux-yocto and
#   oe-core kernel classes to apply a subset of yocto kernel
#   management to git managed kernel repositories.
#
# Warning:
#
#   Building this kernel without providing a defconfig or BSP
#   configuration will result in build or boot errors. This is not a
#   bug.
#
# Notes:
#
#   patches: patches can be merged into to the source git tree itself,
#            added via the SRC_URI, or controlled via a BSP
#            configuration.
#
#   example configuration addition:
#            SRC_URI += "file://smp.cfg"
#   example patch addition:
#            SRC_URI += "file://0001-linux-version-tweak.patch
#   example feature addition:
#            SRC_URI += "file://feature.scc"
#

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

BRANCH = "develop"
LINUX_VERSION ?= "4.14.239"
SRCREV="8433edb6b2e1ff1ae6769364c7fc11f1f0d0992e"

SRC_URI = "git://github.com/iris-GmbH/linux-gen6.git;protocol=https;bareclone=1;branch=${BRANCH};depth=1"

SRC_URI += "file://gen6.scc \
            file://gen6.cfg \
            file://gen6-user-config.cfg \
            file://gen6-user-patches.scc \
           "

SRC_URI += "file://0001-perf-tools-Add-Python-3-support.patch"

PV = "${LINUX_VERSION}+git${SRCPV}"

# KBUILD_DEFCONFIG does not natively work for now, because it does not expand all flags like make xy_defconfig
# -> it expects all flags like in .config (make xy_defconfig)
# -> .config != defconfig
# => workaraound -> run make xy_defconfig to override the prior .config/defconfig

# -> xy_defconfig has to be present below arch/arm/configs in kernel-source
KBUILD_DEFCONFIG:sc572-gen6 = "sc572-gen6_defconfig"
KBUILD_DEFCONFIG:sc573-gen6 = "sc573-gen6_defconfig"
KBUILD_DEFCONFIG:sc573-gen6-4dvein = "sc573-gen6-4dvein_defconfig"

do_makedefconfig() {
	#equal to make ARCH=arm xy_defconfig
	oe_runmake -C ${B} ARCH=${ARCH} ${KBUILD_DEFCONFIG}
}

addtask do_makedefconfig after do_kernel_configme before do_configure

do_createDtbSymlink() {
	cd ${DEPLOY_DIR_IMAGE}
	ln -sf ${KERNEL_DEVICETREE} ${KERNEL_DEVICETREE_SYMLINK}
}

addtask createDtbSymlink after do_deploy before do_build

do_createImageSymlink() {
	cd ${DEPLOY_DIR_IMAGE}
	ln -sf ${KERNEL_IMAGETYPE} ${KERNEL_IMAGE_SYMLINK}
}

addtask do_createImageSymlink after do_deploy before do_build


