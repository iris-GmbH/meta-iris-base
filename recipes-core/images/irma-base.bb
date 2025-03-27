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

    # Add task R2 only for ext4 builds
    image_fstypes = d.getVar('IMAGE_FSTYPES')
    compat_machines = (d.getVar('MACHINEOVERRIDES') or "").split(":")
    if ('mx8mp-nxp-bsp' in compat_machines or 'mx93-nxp-bsp' in compat_machines) and 'ext4' in image_fstypes:
        bb.build.addtask('do_generate_dmverity_hashes', 'do_image_complete', 'do_image_ext4', d)
        d.prependVarFlag('do_generate_dmverity_hashes', 'postfuncs', 'create_symlinks ')
        d.appendVarFlag('do_generate_dmverity_hashes', 'subimages', ' ' + ' '.join(["ext4.roothash", "ext4.roothash.signature", "ext4.hashdevice"]))
}

# Generate dm-verity root hash
SECURE_BOOT_DEPENDS = " cryptsetup-native gzip-native bc-native xxd-native openssl-native"
DEPENDS:append:mx8mp-nxp-bsp = "${SECURE_BOOT_DEPENDS}"
DEPENDS:append:mx93-nxp-bsp = "${SECURE_BOOT_DEPENDS}"
do_generate_dmverity_hashes () {
    blockdev=$(mktemp)
    paddeddev=$(mktemp)
    hashdev=$(mktemp)

    # unzip ext4.gz image to tempfile
    ext4img="${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4.gz"
    gzip -dc "${ext4img}" > "${blockdev}"

    # get size of ext4 image and pad it to next 4MB block
    ext4size=$(stat -c%s "${blockdev}")
    paddedsize=$(echo "(((ext4size/(4*1024*1024)) + ((ext4size % (4*1024*1024)) > 0)) * (4*1024*1024))" | bc)
    cat "${blockdev}" /dev/zero | head -c "${paddedsize}" > "${paddeddev}"

    salt=$(cat ${ROOTHASH_DM_VERITY_SALT})
    output=$(veritysetup format -s "${salt}" "${blockdev}" "${hashdev}")
    roothash=$(echo "$output" | grep "^Root hash:" | cut -f2)

    # write roothash to image directory
    roothashfile="${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4.roothash"
    echo "${roothash}" > "${roothashfile}"

    # sign roothash and write signature to image directory
    roothash_signature_file="${roothashfile}.signature"
    if ! openssl dgst -sha256 -sign "${ROOTHASH_SIGNING_PRIVATE_KEY}" -out "${roothash_signature_file}" "${roothashfile}"
    then
        bbfatal "Signing roothash failed"
        exit 1
    fi

    # copy hash device to image directory
    hashdevfile="${IMGDEPLOYDIR}/${IMAGE_NAME}.ext4.hashdevice"
    cp "${hashdev}" "${hashdevfile}"

    # delete tempfiles
    rm "${blockdev}" "${paddeddev}" "${hashdev}"
}

do_image_version_artifact () {
    echo "${FIRMWARE_VERSION}" > "${IMGDEPLOYDIR}/${IMAGE_NAME}.version"
}

inherit irma6-firmware-zip
