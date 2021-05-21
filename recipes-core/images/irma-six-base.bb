SUMMARY = "A small image just capable of allowing a device to boot."
IMAGE_LINGUAS = " "
LICENSE = "MIT"
inherit irma-six-core-image
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE_append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"
TOOLCHAIN_HOST_TASK += "nativesdk-cmake nativesdk-protobuf-lite nativesdk-protobuf-compiler"
TOOLCHAIN_TARGET_TASK += "googletest"

PV = "${DISTRO_VERSION}"

inherit irma-6-firmware-zip
