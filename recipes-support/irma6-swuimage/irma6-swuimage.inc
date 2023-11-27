# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DESCRIPTION = "Generate irma6 swupdate images"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

IMAGENAME = "${@ d.getVar('PN').replace('-swuimage','')}"
FITIMAGENAME = "irma6-fitimage"

# The following line forces the usage of the "files" directory next to this .inc file even if it is required from another layer
FILESEXTRAPATHS:prepend := "${@os.path.dirname(d.getVar('FILE'))}/files:"

SRC_URI = " \
    file://sw-description \
    file://pre_post_inst.sh \
"

IMAGE_DEPENDS = "\
	${FITIMAGENAME} \
	${IMAGENAME} \
	virtual/kernel \
	${IMAGE_BOOTLOADER} \
"

SWU_BOOTLOADER = "${IMAGE_BOOTLOADER}.signed"
SWU_FITIMAGE = "${FITIMAGENAME}.itb.signed"
SWU_ROOTFS = "${IMAGENAME}-${MACHINE}.ext4.gz"
SWU_ROOTHASH="${IMAGENAME}-${MACHINE}.ext4.roothash"
SWU_ROOTHASH_SIGNATURE="${IMAGENAME}-${MACHINE}.ext4.roothash.signature"
SWU_HASHDEVICE="${IMAGENAME}-${MACHINE}.ext4.hashdevice"
SWU_PRE_POST_SCRIPT = "pre_post_inst.sh"

SWU_META = "${IMAGENAME}-${MACHINE}.testdata.json"

SWU_TARGET_FITIMAGE = "fitImage.signed"

SWU_HW_VERSION ?= "${@'0.0' if not d.getVar('HW_VERSION') else d.getVar('HW_VERSION')}"

# images and files that will be included in the .swu image
SWUPDATE_IMAGES = "${SWU_FITIMAGE} ${SWU_ROOTFS} ${SWU_BOOTLOADER} ${SWU_ROOTHASH} ${SWU_ROOTHASH_SIGNATURE} ${SWU_HASHDEVICE}"

python() {
    if "swupdate" not in (d.getVar('UPDATE_PROCEDURE') or ""):
        raise bb.parse.SkipRecipe('swupdate images can only be build for machines that use this UPDATE_PROCEDURE')
}

python do_swuimage:prepend () {
    import json
    print(d.getVar('IMAGE_LINK_NAME'))
    # read rootfs / irma6 version from meta file
    image_dir = d.getVar('DEPLOY_DIR_IMAGE', True)
    irmameta = json.load(open(os.path.join(image_dir, d.getVar("SWU_META"))))
    fw_version = irmameta['FIRMWARE_VERSION']
    d.setVar("SWU_VERSION_ROOTFS", fw_version)

    # set the swu fw version
    import re
    swu_fw_version = re.search('\d+\.\d+\.\d+', fw_version).group(0)
    d.setVar("SWU_FW_VERSION", swu_fw_version)

    # mark images that needs to be encrypted, before being passed to swu
    def mark_encrypted(artefact):
        d.setVarFlag('SWUPDATE_IMAGES_ENCRYPTED', artefact, '1')

    mark_encrypted(d.getVar('SWU_BOOTLOADER'))
    mark_encrypted(d.getVar('SWU_FITIMAGE'))
    mark_encrypted(d.getVar('SWU_ROOTFS'))
    mark_encrypted(d.getVar('SWU_PRE_POST_SCRIPT'))
    mark_encrypted(d.getVar('SWU_ROOTHASH'))
    mark_encrypted(d.getVar('SWU_ROOTHASH_SIGNATURE'))
    mark_encrypted(d.getVar('SWU_HASHDEVICE'))

    # The iv is changed with each swu
    key,iv = swupdate_extract_keys(d.getVar('SWUPDATE_AES_FILE', True))
    d.setVar("SWU_IVT", iv)
}

inherit swupdate
