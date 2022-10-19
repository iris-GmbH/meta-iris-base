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
	openssl-bin \
	libubootenv-bin \
	iris-ca-certificates \
	iris-signing \
	rsyslog \
	chrony \
	chronyc \
	hab-csf-parser \
	hab-srktool-scripts \
	nftables \
"
# IRMA6R2 SoC specific packages (not included in qemu)
IRMA6_EXTRA_PACKAGES_append_mx8mp = " \
	keyctl-caam \
	util-linux-blockdev \
	keyutils \
	mmc-utils \
	dosfstools \
	e2fsprogs-mke2fs \
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

    # Add task R2 only for ext4 builds
    image_fstypes = d.getVar('IMAGE_FSTYPES')
    compat_machines = (d.getVar('MACHINEOVERRIDES') or "").split(":")
    if 'mx8mp' in compat_machines and 'ext4' in image_fstypes:
        bb.build.addtask('do_generate_dmverity_hashes', 'do_image_complete', 'do_image_ext4', d)
}

# Generate dm-verity root hash for R2
DEPENDS_append_mx8mp = " cryptsetup-native gzip-native bc-native xxd-native openssl-native"
do_generate_dmverity_hashes () {
    blockdev=$(mktemp)
    paddeddev=$(mktemp)
    hashdev=$(mktemp)

    # unzip ext4.gz image to tempfile
    ext4img="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ext4.gz"
    gzip -dc "${ext4img}" > "${blockdev}"

    # get size of ext4 image and pad it to next 4MB block
    ext4size=$(stat -c%s "${blockdev}")
    paddedsize=$(echo "(((ext4size/(4*1024*1024)) + ((ext4size % (4*1024*1024)) > 0)) * (4*1024*1024))" | bc)
    cat "${blockdev}" /dev/zero | head -c "${paddedsize}" > "${paddeddev}"

    salt=$(cat ${ROOTHASH_DM_VERITY_SALT})
    output=$(veritysetup format -s "${salt}" "${blockdev}" "${hashdev}")
    roothash=$(echo "$output" | grep "^Root hash:" | cut -f2)

    # write roothash to image directory
    roothashfile="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ext4.roothash"
    echo "${roothash}" > "${roothashfile}"

    # sign roothash and write signature to image directory
    roothash_signature_file="${roothashfile}.signature"
    if ! openssl dgst -sha256 -sign "${ROOTHASH_SIGNING_PRIVATE_KEY}" -out "${roothash_signature_file}" "${roothashfile}"
    then
        bbfatal "Signing roothash failed"
        exit 1
    fi

    # copy hash device to image directory
    hashdevfile="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ext4.hashdevice"
    cp "${hashdev}" "${hashdevfile}"

    # create symlinks
    roothash_sym="${IMGDEPLOYDIR}/${PN}-${MACHINE}.ext4.roothash"
    roothash_sig_sym="${IMGDEPLOYDIR}/${PN}-${MACHINE}.ext4.roothash.signature"
    hashdevice_sym="${IMGDEPLOYDIR}/${PN}-${MACHINE}.ext4.hashdevice"

    ln -sfr "${roothashfile}" "${roothash_sym}"
    ln -sfr "${roothash_signature_file}" "${roothash_sig_sym}"
    ln -sfr "${hashdevfile}" "${hashdevice_sym}"

    # delete tempfiles
    rm "${blockdev}" "${paddeddev}" "${hashdev}"
}

# The rootfs on R2 is read-only, so the timestamp must be saved in a r/w location
# Skip writing of "default" timestamp in /etc/timestamp (as this file will never be used)
ROOTFS_POSTPROCESS_COMMAND_remove_mx8mp = "rootfs_update_timestamp"

# Set timestamp file. /etc/default/timestamp will be sourced by the init-scripts
add_default_timestamp_location(){
    echo "TIMESTAMP_FILE=/mnt/iris/timestamp" > ${IMAGE_ROOTFS}${sysconfdir}/default/timestamp
}
ROOTFS_POSTPROCESS_COMMAND_append_mx8mp = "add_default_timestamp_location; "

inherit irma6-firmware-zip
