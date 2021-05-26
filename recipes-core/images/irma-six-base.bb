SUMMARY = "A small image just capable of allowing a device to boot."
IMAGE_LINGUAS = " "
LICENSE = "MIT"
inherit irma-six-core-image
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE_append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"
TOOLCHAIN_HOST_TASK += "nativesdk-cmake nativesdk-protobuf-lite nativesdk-protobuf-compiler"
TOOLCHAIN_TARGET_TASK += "googletest"

PV = "${DISTRO_VERSION}"

# this cannot be done directly in the os-release recipe, due to yocto's buttom-up approach
# os-release does not know how the final image will be named, as the IMAGE_NAME variable is out of scope
add_image_name_to_os_release(){
    echo "IMAGE_NAME=${IMAGE_NAME}" >> ${IMAGE_ROOTFS}${sysconfdir}/os-release
}

ROOTFS_POSTPROCESS_COMMAND += "add_image_name_to_os_release; "

inherit irma-6-firmware-zip
