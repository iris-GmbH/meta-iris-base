# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

inherit irma6-bootloader-version hab hab-compatibility-check
PV = "${IRIS_IMX_BOOT_RELEASE}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://${HAB_DIR}/csf.cfg"
SRC_URI:append:hab4 = " \
    file://0001-Use-imx8mp-irma6r2.dtb-instead-of-imx8mp-ddr4-evk.dt.patch \
"

SRC_URI:append:ahab = " \
    file://0001-Add-flash_fitimage-for-imx93.patch \
"

python __anonymous () {
    overrides = d.getVar('OVERRIDES', True).split(':')
    if 'hab4' in overrides or 'ahab' in overrides:
        d.appendVar("DEPENDS", " cst-native cst-signer-native")
}

set_imxboot_vars() {
    for target in ${IMXBOOT_TARGETS}; do
        # Use first "target" as IMAGE_IMXBOOT_TARGET
        if [ "$IMAGE_IMXBOOT_TARGET" = "" ]; then
	        IMAGE_IMXBOOT_TARGET="$target"
        fi
    done
    BOOT_CONFIG_MACHINE_EXTRA="imx-boot-${MACHINE}-${UBOOT_CONFIG}.bin"
    BOOT_IMAGE_SD="${BOOT_CONFIG_MACHINE_EXTRA}-${IMAGE_IMXBOOT_TARGET}"
}

do_sign_boot_image() {
    bbwarn "Signed boot not enabled."
}

sign_boot_image() {
	SIGNDIR="${S}"
    set_imxboot_vars
    bbnote "Signing boot image ${BOOT_IMAGE_SD}"

    # Check if SD image is available
    if [ ! -e "${SIGNDIR}/${BOOT_IMAGE_SD}" ]; then
        bbfatal 'imx-boot SD image is not available to sign'
    fi

    # Generate signed image using cst_signer
	cd "${SIGNDIR}"
    CST_EXE_PATH=cst CST_PATH=${HAB_DIR} cst_signer -d -i ${SIGNDIR}/${BOOT_IMAGE_SD} -c ${SIGNDIR}/csf.cfg
    if [ ! -e "${SIGNDIR}/signed-${BOOT_IMAGE_SD}" ]; then
        bbfatal "Image signing failed"
    fi
    mv ${SIGNDIR}/signed-${BOOT_IMAGE_SD} ${SIGNDIR}/${BOOT_IMAGE_SD}.signed

    check_srk_compatibility ${SIGNDIR}/${BOOT_IMAGE_SD}.signed
}

do_sign_boot_image:hab4() {
    install -m 0755 ${HAB_DIR}/csf.cfg ${S}/csf.cfg
    sign_boot_image
}

do_sign_boot_image:ahab() {
    install -m 0755 ${HAB_DIR}/csf.cfg ${S}/csf.cfg
    sign_boot_image
}

addtask do_sign_boot_image before do_deploy do_install after do_compile

install_boot_image() {
    # For the uuu-container build
    set_imxboot_vars
    install -m 0644 ${S}/${BOOT_IMAGE_SD}.signed ${D}/boot/
    check_iris_version_string
}

do_install:append:hab4() {
    install_boot_image
}

do_install:append:ahab() {
    install_boot_image
}

deploy_boot_image() {
    set_imxboot_vars
    if [ -e "${S}/${BOOT_IMAGE_SD}.signed" ]; then
        install -m 0644 ${S}/${BOOT_IMAGE_SD}.signed ${DEPLOYDIR}/
        cd ${DEPLOYDIR}
        ln -sf ${BOOT_IMAGE_SD}.signed imx-boot.signed
    else
        bbfatal "ERROR: Could not deploy Signed image"
    fi
}

do_deploy:append:hab4() {
    deploy_boot_image
}

do_deploy:append:ahab() {
    deploy_boot_image
}

check_iris_version_string() {
    set_imxboot_vars
    bootloader="${S}/${BOOT_IMAGE_SD}.signed"

    # Find the first occurence of "U-Boot SPL [...]" in the first 1MB and check for pattern: iris-boot_X.X.X+gYYY
    # Do exactly the same as here: meta-iris-base/recipes-support/swupdate/swupdate/bootloader_update.lua,
    # but during build.
    input_string=$(dd if="$bootloader" bs=1M count=1 2>/dev/null | strings | grep "U-Boot SPL" | head -n 1)
    pattern="iris-boot_[0-9]+\.[0-9]+\.[0-9]+\+(\w+)"
    if [ -n "$input_string" ] && echo "$input_string" | grep -q -E "$pattern"; then
        version_string=$(echo "$input_string" | grep -Eo "$pattern" | head -n 1)
        bbnote "iris version string found: $version_string"
    else
        bberror "iris version string not found in $bootloader"
    fi
}
