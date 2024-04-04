# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

SUMMARY = "The iris custom Linux distribution, minus our proprietary platform application."
IMAGE_LINGUAS = " "
LICENSE = "MIT"
inherit irma-core-image
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"
TOOLCHAIN_HOST_TASK += " \
    nativesdk-make \
    nativesdk-cmake \
    nativesdk-protobuf-lite \
    nativesdk-protobuf-compiler \
    nativesdk-ccache \
    nativesdk-python3-gcovr \
    nativesdk-git \
"
TOOLCHAIN_TARGET_TASK += "googletest"

PV = "${DISTRO_VERSION}"
inherit irma-firmware-versioning

IRMA_MATRIX_BASE_PACKAGES = " \
"

IMAGE_INSTALL:append = " \
    ${IRMA_MATRIX_BASE_PACKAGES} \
"

# Include swupdate in image if swupdate is part of the update procedure
IMAGE_INSTALL:append = " ${@bb.utils.contains('UPDATE_PROCEDURE', 'swupdate', 'swupdate swupdate-www', '', d)}"

# this cannot be done directly in the os-release recipe, due to yocto's buttom-up approach
# os-release does not know how the final image will be named, as the IMAGE_NAME variable is out of scope
add_image_name_to_os_release(){
    echo "IMAGE_NAME=\"${IMAGE_NAME}\"" >> ${IMAGE_ROOTFS}${sysconfdir}/os-release
    echo "FIRMWARE_VERSION=\"${FIRMWARE_VERSION}\"" >> ${IMAGE_ROOTFS}${sysconfdir}/os-release
}

ROOTFS_POSTPROCESS_COMMAND += "add_image_name_to_os_release; "

