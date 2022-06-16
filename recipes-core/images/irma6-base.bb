# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

SUMMARY = "The iris custom Linux distribution, minus our proprietary platform application."
IMAGE_LINGUAS = " "
LICENSE = "MIT"
inherit irma6-core-image
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE_append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"
TOOLCHAIN_HOST_TASK += "nativesdk-cmake nativesdk-protobuf-lite nativesdk-protobuf-compiler"
TOOLCHAIN_TARGET_TASK += "googletest"

PV = "${DISTRO_VERSION}"
inherit irma6-versioning

IRMA6_BASE_PACKAGES = " \
	libstdc++ \
	libssl \
	avahi-daemon \
	libavahi-client \
	libavahi-common \
	libavahi-core \
	protobuf-lite \
	zlib \
	yaml-cpp \
	libelf \
	libxml2 \
	nginx \
	sqlite3 \
"

# IRMA6 default (Release 2) only packages
IRMA6_EXTRA_PACKAGES = " \
	lvm2 \
	cryptsetup \
	libubootenv-bin \
"
# IRMA6R2 SoC specific packages (not included in qemu)
IRMA6_EXTRA_PACKAGES_append_mx8mp = " \
	keyctl-caam \
	util-linux-blockdev \
	keyutils \
	mmc-utils \
"

# IRMA6 Release 1 only packages
IRMA6_EXTRA_PACKAGES_sc57x = " \
"

IMAGE_INSTALL_append = " \
	${IRMA6_BASE_PACKAGES} \
	${IRMA6_EXTRA_PACKAGES} \
"

# Include swupdate in image if swupdate is part of the update procedure
IMAGE_INSTALL_append = " ${@bb.utils.contains('UPDATE_PROCEDURE', 'swupdate', 'swupdate swupdate-www', '', d)}"

# this cannot be done directly in the os-release recipe, due to yocto's buttom-up approach
# os-release does not know how the final image will be named, as the IMAGE_NAME variable is out of scope
add_image_name_to_os_release(){
    echo "IMAGE_NAME=\"${IMAGE_NAME}\"" >> ${IMAGE_ROOTFS}${sysconfdir}/os-release
    echo "FIRMWARE_VERSION=\"${FIRMWARE_VERSION}\"" >> ${IMAGE_ROOTFS}${sysconfdir}/os-release
}

ROOTFS_POSTPROCESS_COMMAND += "add_image_name_to_os_release; "

# save the firmware version at /etc/version.
# Although this probably is not a good idea (modifies file from deep within the yocto build system), this is done for backwards compatibility reasons
replace_etc_version () {
	echo "${FIRMWARE_VERSION}" > ${IMAGE_ROOTFS}${sysconfdir}/version
}

# simply appending to ROOTFS_POSTPROCESS_COMMAND is not enough, as we need to run this after
# https://git.yoctoproject.org/cgit/cgit.cgi/poky/tree/meta/classes/rootfs-postcommands.bbclass?h=dunfell&id=43060f59ba60a0257864f1f7b25b51fac3f2d2cf#n57
python () {
    d.appendVar('ROOTFS_POSTPROCESS_COMMAND', 'replace_etc_version;')
}

inherit irma6-firmware-zip
