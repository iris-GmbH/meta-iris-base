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

do_install[depends] = "\
    ${IMAGENAME}:do_image_complete \
    ${@'${IMAGENAME}:do_createfirmwarezip' if d.getVar('IRMA6_RELEASE') == '1' else '${IMAGENAME}-swuimage:do_swuimage ${IMAGENAME}-uuu:do_deploy'} \
"

