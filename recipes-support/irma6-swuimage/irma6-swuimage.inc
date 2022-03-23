# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Generate irma6 swupdate images"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

IMAGENAME = "${@ d.getVar('PN').replace('-swuimage','')}"

# The following line forces the usage of the "files" directory next to this .inc file even if it is required from another layer
FILESEXTRAPATHS_prepend := "${@os.path.dirname(d.getVar('FILE'))}/files:"

SRC_URI = " \
    file://sw-description \
    file://update_firmware.sh \
"

IMAGE_DEPENDS = "\
	${IMAGENAME} \
	virtual/kernel \
"

SWU_KERNEL = "Image-${MACHINE}.bin"
SWU_DEVTREE = "${MACHINE}.dtb"
SWU_ROOTFS = "${IMAGENAME}-${MACHINE}.ext4.gz"
SWU_META = "${IMAGENAME}-${MACHINE}.testdata.json"

SWU_TARGET_KERNEL = "Image"
SWU_TARGET_DEVTREE = "${MACHINE}.dtb"

SWU_HW_VERSION = "1.0"

# images and files that will be included in the .swu image
SWUPDATE_IMAGES = "${SWU_KERNEL} ${SWU_DEVTREE} ${SWU_ROOTFS}"

python() {
    if "swupdate" not in (d.getVar('UPDATE_PROCEDURE') or ""):
        raise bb.parse.SkipRecipe('swupdate images can only be build for machines that use this UPDATE_PROCEDURE')
}

python do_swuimage_prepend () {
    import json
    print(d.getVar('IMAGE_LINK_NAME'))
    # read rootfs / irma6 version from meta file
    image_dir = d.getVar('DEPLOY_DIR_IMAGE', True)
    irmameta = json.load(open(os.path.join(image_dir, d.getVar("SWU_META"))))
    d.setVar("SWU_VERSION_ROOTFS", irmameta['FIRMWARE_VERSION'])
}

inherit swupdate