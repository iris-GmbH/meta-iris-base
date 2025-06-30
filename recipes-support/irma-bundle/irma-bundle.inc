# SPDX-License-Identifier: MIT
# Copyright (C) 2023 iris-GmbH infrared & intelligent sensors

LICENSE = "MIT"

IMAGENAME = "${@ d.getVar('PN').replace('-bundle','')}"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# do nothing, package nothing, deploy nothing
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"
do_package[noexec] = "1"
do_packagedata[noexec] = "1"
deltask package_write_ipk
deltask package_write_deb
deltask package_write_rpm

# default: create swuimage and uuu bundles, on R1: create firmware.zip
ADDITIONAL_INSTALL_DEPENDS = "${IMAGENAME}-swuimage:do_swuimage ${IMAGENAME}-uuu:do_deploy"
ADDITIONAL_INSTALL_DEPENDS:poky-iris-0601 = "${IMAGENAME}:do_createfirmwarezip"

do_install[depends] = "\
    ${IMAGENAME}:do_image_complete \
    ${ADDITIONAL_INSTALL_DEPENDS} \
"

