# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

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

IRIS_TOOLCHAIN_TARGET_TASK = " \
    libstdc++-staticdev \
    googletest \
    protobuf \
    dlib \
    nlohmann-json \
    json-schema-validator \
    libnmea \
    libpng \
"

# protobuf-staticdev only exists on scarthgap, swupdate is not used on R1
ADDITIONAL_IRIS_TOOLCHAIN_TARGET_TASK = "protobuf-staticdev swupdate"

# manually include blasfeo for R1 since it is statically linked
ADDITIONAL_IRIS_TOOLCHAIN_TARGET_TASK:poky-iris-0601 = "blasfeo-staticdev"

TOOLCHAIN_TARGET_TASK:append = " ${IRIS_TOOLCHAIN_TARGET_TASK} ${ADDITIONAL_IRIS_TOOLCHAIN_TARGET_TASK}"

PV = "${DISTRO_VERSION}"
inherit irma-firmware-versioning

IRMA_BASE_PACKAGES = " \
    iris-ca-certificates \
    factory-reset \
    set-hostname \
"

IRMA_EXTRA_PACKAGES = " \
    iris-signing \
    rsyslog \
    chrony \
    nftables \
    wpa-supplicant \
    udev-extraconf-iris \
    switch-log-location \
    set-mount-permissions \
    save-rtc \
"
IRMA_EXTRA_PACKAGES:append = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', ' remount-nfs-root', '', d)}"

# install no extra packages on R1
IRMA_EXTRA_PACKAGES:poky-iris-0601 = " \
"

IMAGE_INSTALL:append = " ${IRMA_BASE_PACKAGES} ${IRMA_EXTRA_PACKAGES}"

# Include swupdate in image if swupdate is part of the update procedure
IMAGE_INSTALL:append = " ${@bb.utils.contains('UPDATE_PROCEDURE', 'swupdate', 'swupdate swupdate-www', '', d)}"

# this cannot be done directly in the os-release recipe, due to yocto's buttom-up approach
# os-release does not know how the final image will be named, as the IMAGE_NAME variable is out of scope
add_image_name_to_os_release(){
    echo "IMAGE_NAME=\"${IMAGE_NAME}\"" >> ${IMAGE_ROOTFS}${sysconfdir}/os-release
    echo "FIRMWARE_VERSION=\"${FIRMWARE_VERSION}\"" >> ${IMAGE_ROOTFS}${sysconfdir}/os-release
}

setup_machine_id() {
    # Generate a persistent machine-id for systemd
    if [ ! -f ${IMAGE_ROOTFS}/etc/machine-id ]; then
        cat /proc/sys/kernel/random/uuid | tr -d '-' > ${IMAGE_ROOTFS}/etc/machine-id
    fi
}

ROOTFS_POSTPROCESS_COMMAND += "add_image_name_to_os_release; "
ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'setup_machine_id;', '', d)}"

# save the firmware version at /etc/version.
# Although this probably is not a good idea (modifies file from deep within the yocto build system), this is done for backwards compatibility reasons
replace_etc_version () {
    echo "${FIRMWARE_VERSION}" > ${IMAGE_ROOTFS}${sysconfdir}/version
}

# simply appending to ROOTFS_POSTPROCESS_COMMAND is not enough, as we need to run this after
# https://git.yoctoproject.org/cgit/cgit.cgi/poky/tree/meta/classes/rootfs-postcommands.bbclass?h=dunfell&id=43060f59ba60a0257864f1f7b25b51fac3f2d2cf#n57
python () {
    d.appendVar('ROOTFS_POSTPROCESS_COMMAND', 'replace_etc_version;')

    # Create .version file as image artifact
    bb.build.addtask('do_image_version_artifact', 'do_image_complete', 'do_image', d)
    d.prependVarFlag('do_image_version_artifact', 'postfuncs', 'create_symlinks ')
    d.appendVarFlag('do_image_version_artifact', 'subimages', ' version')
}

IRMA_IMAGE_INHERIT = "signed-verity-image"
IRMA_IMAGE_INHERIT:poky-iris-0601 = "irma6-firmware-zip"
inherit ${IRMA_IMAGE_INHERIT}

do_image_version_artifact () {
    echo "${FIRMWARE_VERSION}" > "${IMGDEPLOYDIR}/${IMAGE_NAME}.version"
}
