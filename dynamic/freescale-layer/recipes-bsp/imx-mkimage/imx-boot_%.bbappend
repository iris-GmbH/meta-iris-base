# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

require imx-mkimage_iris.inc

inherit irma6-bootloader-version hab
PV = "${IRIS_IMX_BOOT_RELEASE}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:hab4 = " \
    file://0001-Use-imx8mp-irma6r2.dtb-instead-of-imx8mp-ddr4-evk.dt.patch \
    file://csf_hab4.cfg \
"

SRC_URI:append:ahab = " \
    file://csf_ahab.cfg \
    file://0001-Add-flash_fitimage-for-imx93.patch \
"

# Make irma-fitimage as dependent on the do_compile task of imx-boot
COMPILE_DEPENDS = ""
COMPILE_DEPENDS:ahab = " \
    irma-fitimage:do_assemble_fit \
    irma-fitimage-uuu:do_assemble_fit \
"
do_compile[depends] += "${COMPILE_DEPENDS}"

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
    BOOT_CONFIG_MACHINE_EXTRA="${BOOT_NAME}-${MACHINE}-${UBOOT_CONFIG}.bin"
    BOOT_IMAGE_SD="${BOOT_CONFIG_MACHINE_EXTRA}-${IMAGE_IMXBOOT_TARGET}"
}

do_sign_boot_image() {
    bbwarn "Signed boot not enabled."
}

sign_boot_image() {
    bbnote "Signing boot image"
	SIGNDIR="${S}"
    set_imxboot_vars

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
}

do_sign_boot_image:hab4() {
    install -m 0755 ${WORKDIR}/csf_hab4.cfg ${S}/csf.cfg
    sign_boot_image
}

do_sign_boot_image:ahab() {
    install -m 0755 ${WORKDIR}/csf_ahab.cfg ${S}/csf.cfg
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
        install -m 0644 ${S}/${BOOT_IMAGE_SD}.signed ${DEPLOY_DIR_IMAGE}/
        ln -sf ${DEPLOY_DIR_IMAGE}/${BOOT_IMAGE_SD}.signed ${DEPLOY_DIR_IMAGE}/${BOOT_NAME}.signed
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

do_compile:append:ahab() {
    # Create flash.bin for the uuu kernel fitimage -> flash_os.bin.uuu
    cp ${DEPLOY_DIR_IMAGE}/irma-fitimage-uuu.itb ${BOOT_STAGING}/irma-fitimage-uuu.itb
    FITIMAGE=irma-fitimage-uuu.itb make SOC=${IMX_BOOT_SOC_TARGET} flash_fitimage
    mv ${BOOT_STAGING}/flash_os.bin ${BOOT_STAGING}/flash_os.bin.uuu

    # Create flash.bin for the kernel fitimage -> flash_os.bin
    cp ${DEPLOY_DIR_IMAGE}/irma-fitimage.itb ${BOOT_STAGING}/irma-fitimage.itb
    FITIMAGE=irma-fitimage.itb make SOC=${IMX_BOOT_SOC_TARGET} flash_fitimage
}

do_sign_fitimage() {
    :
}

do_sign_fitimage:ahab() {
    bbnote "Signing fitimage"

    SIGNDIR="${S}"
    if [ ! -f ${SIGNDIR}/csf.cfg ]; then
        install -m 0755 ${WORKDIR}/csf_ahab.cfg ${SIGNDIR}/csf.cfg
    fi

    # Generate signed fitimage using cst_signer
    cd "${SIGNDIR}"
    CST_EXE_PATH=cst CST_PATH=${HAB_DIR} cst_signer -d -i ${BOOT_STAGING}/flash_os.bin -c ${SIGNDIR}/csf.cfg
    mv ${SIGNDIR}/signed-flash_os.bin ${SIGNDIR}/irma-fitimage.itb.signed

    # Generate signed fitimage-uuu using cst_signer
    CST_EXE_PATH=cst CST_PATH=${HAB_DIR} cst_signer -d -i ${BOOT_STAGING}/flash_os.bin.uuu -c ${SIGNDIR}/csf.cfg
    mv ${SIGNDIR}/signed-flash_os.bin.uuu ${SIGNDIR}/irma-fitimage-uuu.itb.signed
}


addtask do_sign_fitimage before do_deploy do_install after do_sign_boot_image

do_deploy:append:ahab() {
    if [ -e "${S}/irma-fitimage.itb.signed" ]; then
        install -m 0644 ${S}/irma-fitimage.itb.signed ${DEPLOYDIR}
        install -m 0644 ${S}/irma-fitimage-uuu.itb.signed ${DEPLOYDIR}
    else
        bbfatal "Could not deploy Signed fitimage"
    fi
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
