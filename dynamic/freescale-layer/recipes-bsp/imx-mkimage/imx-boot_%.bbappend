# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

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
COMPILE_DEPENDS:hab4 = " \
    irma-fitimage:do_assemble_fit \
    irma-fitimage-uuu:do_assemble_fit \
"
do_compile[depends] += "${COMPILE_DEPENDS}"

FITIMAGE_NAME = "irma-fitimage.itb"
FITIMAGE_UUU_NAME = "irma-fitimage-uuu.itb"
FITLOADADDR:mx8mp-nxp-bsp = "0x48000000"

python __anonymous () {
    overrides = d.getVar('OVERRIDES', True).split(':')
    if 'hab4' in overrides or 'ahab' in overrides:
        d.appendVar("DEPENDS", " cst-native cst-signer-native perl-native")
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
        ln -srf ${DEPLOY_DIR_IMAGE}/${BOOT_IMAGE_SD}.signed ${DEPLOY_DIR_IMAGE}/imx-boot.signed
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
    cp ${DEPLOY_DIR_IMAGE}/${FITIMAGE_UUU_NAME} ${BOOT_STAGING}/${FITIMAGE_UUU_NAME}
    FITIMAGE=${FITIMAGE_UUU_NAME} make SOC=${IMX_BOOT_SOC_TARGET} flash_fitimage
    mv ${BOOT_STAGING}/flash_os.bin ${BOOT_STAGING}/flash_os.bin.uuu

    # Create flash.bin for the kernel fitimage -> flash_os.bin
    cp ${DEPLOY_DIR_IMAGE}/${FITIMAGE_NAME} ${BOOT_STAGING}/${FITIMAGE_NAME}
    FITIMAGE=${FITIMAGE_NAME} make SOC=${IMX_BOOT_SOC_TARGET} flash_fitimage
}

attach_ivt() {
	if [ -z "${FITLOADADDR}" ]; then
		bbfatal "FITLOADADDR is not set!"
	fi

	IMAGE_SIZE="`wc -c < ${1}`"
	get_align_size_emit_file get_align_size.pl
	genivt_emit_file imx6-genIVT.pl
	ALIGNED_SIZE="$(perl -w get_align_size.pl ${IMAGE_SIZE})"
	objcopy -I binary -O binary --pad-to ${ALIGNED_SIZE} --gap-fill=0x00 ${1} ${1}-pad
	perl -w imx6-genIVT.pl ${FITLOADADDR} `printf "0x%x" ${ALIGNED_SIZE}`
	cat ${1}-pad ivt.bin > ${1}-ivt
	rm -f ${1}-pad
}

get_align_size_emit_file() {

	cat << 'EOF' > ${1}
use strict;
my $image_size = $ARGV[0];
my $aligned_size = (($image_size + 0x1000 - 1)  & ~ (0x1000 - 1));
print  "$aligned_size\n";
EOF
}

genivt_emit_file() {

	cat << 'EOF' > ${1}
use strict;
my $loadaddr = hex(shift);
my $img_size = hex(shift);

my $entry = $loadaddr;
my $ivt_addr = $loadaddr + $img_size;
my $csf_addr = $ivt_addr + 0x20;

open(my $out, '>:raw', 'ivt.bin') or die "Unable to open: $!";
print $out pack("V", 0x412000D1); # IVT Header
print $out pack("V", $entry); # Jump Location
print $out pack("V", 0x0); # Reserved
print $out pack("V", 0x0); # DCD pointer
print $out pack("V", 0x0); # Boot Data
print $out pack("V", $ivt_addr); # Self Pointer
print $out pack("V", $csf_addr); # CSF Pointer
print $out pack("V", 0x0); # Reserved
close($out);
EOF
}

do_compile:append:hab4() {
    # Copy fitimage
    cp ${DEPLOY_DIR_IMAGE}/${FITIMAGE_NAME} ${BOOT_STAGING}/${FITIMAGE_NAME}
    cp ${DEPLOY_DIR_IMAGE}/${FITIMAGE_UUU_NAME} ${BOOT_STAGING}/${FITIMAGE_UUU_NAME}

    # Append Image Vector Table
    attach_ivt ${BOOT_STAGING}/${FITIMAGE_NAME}
    attach_ivt ${BOOT_STAGING}/${FITIMAGE_UUU_NAME}

    # Create the kernel (uuu) fitimage'S -> flash_os.bin, flash_os.bin.uuu
    mv ${BOOT_STAGING}/${FITIMAGE_NAME}-ivt ${BOOT_STAGING}/flash_os.bin
    mv ${BOOT_STAGING}/${FITIMAGE_UUU_NAME}-ivt ${BOOT_STAGING}/flash_os.bin.uuu
}

do_sign_fitimage() {
    bbwarn "Signed fitimage not enabled."
}

sign_fitimage() {
    bbnote "Signing fitimage"

    SIGNDIR="${S}"
    if [ ! -f ${SIGNDIR}/csf.cfg ]; then
        install -m 0755 ${WORKDIR}/csf_ahab.cfg ${SIGNDIR}/csf.cfg
    fi

    # Generate signed fitimage using cst_signer
    cd "${SIGNDIR}"
    CST_EXE_PATH=cst CST_PATH=${HAB_DIR} cst_signer -d -i ${BOOT_STAGING}/flash_os.bin -c ${SIGNDIR}/csf.cfg
    mv ${SIGNDIR}/signed-flash_os.bin ${SIGNDIR}/${FITIMAGE_NAME}.signed

    # Generate signed fitimage-uuu using cst_signer
    CST_EXE_PATH=cst CST_PATH=${HAB_DIR} cst_signer -d -i ${BOOT_STAGING}/flash_os.bin.uuu -c ${SIGNDIR}/csf.cfg
    mv ${SIGNDIR}/signed-flash_os.bin.uuu ${SIGNDIR}/${FITIMAGE_UUU_NAME}.signed
}

do_sign_fitimage:hab4() {
    sign_fitimage
}

do_sign_fitimage:ahab() {
    sign_fitimage
}

addtask do_sign_fitimage before do_deploy do_install after do_sign_boot_image

deploy_fitimage() {
    if [ -e "${S}/${FITIMAGE_NAME}.signed" ] || [ -e "${S}/${FITIMAGE_UUU_NAME}.signed" ]; then
        install -m 0644 ${S}/${FITIMAGE_NAME}.signed ${DEPLOYDIR}
        install -m 0644 ${S}/${FITIMAGE_UUU_NAME}.signed ${DEPLOYDIR}
    else
        bbfatal "Could not deploy Signed fitimage"
    fi
}

do_deploy:append:ahab() {
    deploy_fitimage
}

do_deploy:append:hab4() {
    deploy_fitimage
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
