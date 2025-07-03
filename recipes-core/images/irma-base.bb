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
ADDITIONAL_IRIS_TOOLCHAIN_TARGET_TASK:poky-iris-0601 = ""

TOOLCHAIN_TARGET_TASK:append = " ${IRIS_TOOLCHAIN_TARGET_TASK} ${ADDITIONAL_IRIS_TOOLCHAIN_TARGET_TASK}"

PV = "${DISTRO_VERSION}"
inherit irma-firmware-versioning

IRMA_BASE_PACKAGES = " \
	iris-ca-certificates \
"

IRMA_EXTRA_PACKAGES = " \
	iris-signing \
	rsyslog \
	chrony \
	nftables \
	wpa-supplicant \
"

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

    # Create .version file as image artifact
    bb.build.addtask('do_image_version_artifact', 'do_image_complete', 'do_image', d)
    d.prependVarFlag('do_image_version_artifact', 'postfuncs', 'create_symlinks ')
    d.appendVarFlag('do_image_version_artifact', 'subimages', ' version')

    # Add do_finalize_dmverity() task when creating a verity image
    if 'verity' in d.getVar('IMAGE_FSTYPES'):
        # Reduce the overhead factor to 1, because the verity rootfs will be read-only and free space is useless
        d.setVar('IMAGE_OVERHEAD_FACTOR', '1.0')

        # Add do_finalize_dmverity() task
        bb.build.addtask('do_finalize_dmverity', 'do_image_complete', 'do_image_verity', d)
        d.prependVarFlag('do_finalize_dmverity', 'postfuncs', 'create_symlinks ')
        d.appendVarFlag('do_finalize_dmverity', 'subimages', ' ' + ' '.join(["ext4.roothash", "ext4.roothash.signature", "ext4.verity.gz"]))
}

python do_image_verity:prepend () {
    # We need to open an external file (ROOTHASH_DM_VERITY_SALT read into VERITY_SALT). Setting these variables in the
    # parsing phase with an anonymous python function leads to "basehash/taskhash changed" errors. So we prepend these
    # steps here to the do_image_verity() function.

    # read dm-verity salt to variable
    d.setVar('VERITY_SALT', open(d.getVar('ROOTHASH_DM_VERITY_SALT'), 'r').read().strip())

    # Set HASHDEV_SUFFIX so the dmverity image class creates a seperate hashdevice image
    d.setVar('VERITY_IMAGE_HASHDEV_SUFFIX', '.hashdevice')
}

IRMA_IMAGE_INHERIT = "image_types_verity"
IRMA_IMAGE_INHERIT:poky-iris-0601 = "irma6-firmware-zip"
inherit ${IRMA_IMAGE_INHERIT}

# DEPEND on openssl and gzip
do_finalize_dmverity[depends] += "openssl-native:do_populate_sysroot pigz-native:do_populate_sysroot"

do_finalize_dmverity () {
    # Compress verity image, unfortunately "verity.gz" does not work as IMAGE_FSTYPES as verity does not utilize the image creation core logic
    # Command copied from poky - image_types.bbclass - CONVERSION_CMD:gz
    gzip -f -9 -n -c --rsyncable ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4.verity > ${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4.verity.gz

    # write roothash to image directory
    verity_params="${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4.verity-params"
    roothashfile="${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4.roothash"
    sed -ne '/VERITY_ROOT_HASH/s/VERITY_ROOT_HASH=//p' "${verity_params}" > "${roothashfile}"

    # sign roothash and write signature to image directory
    roothash_signature_file="${roothashfile}.signature"
    if ! openssl dgst -sha256 -sign "${ROOTHASH_SIGNING_PRIVATE_KEY}" -out "${roothash_signature_file}" "${roothashfile}"
    then
        bbfatal "Signing roothash failed"
        exit 1
    fi
}

do_image_version_artifact () {
    echo "${FIRMWARE_VERSION}" > "${IMGDEPLOYDIR}/${IMAGE_NAME}.version"
}
