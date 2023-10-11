# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

inherit irma6-bootloader-version
PV = "${IRIS_IMX_BOOT_RELEASE}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:imx8mp-irma6r2 = " \
    file://0001-Use-imx8mp-irma6r2.dtb-instead-of-imx8mp-ddr4-evk.dt.patch \
"

python __anonymous () {
    if d.getVar('HAB_ENABLE', True):
        d.appendVar("DEPENDS", " cst-native")
}

hex2dec() {
    echo $(printf '%d' $1)
}

#
# do_compile must be overwritten because the "make" outputs are required for
# the further signature process. The outputs are stored in the files
# hab_info1.txt and hab_info2.txt.
#
do_compile() {
    # mkimage for i.MX8
    # Copy TEE binary to SoC target folder to mkimage
    if ${DEPLOY_OPTEE}; then
        cp ${DEPLOY_DIR_IMAGE}/tee.bin ${BOOT_STAGING}
    fi
   for type in ${UBOOT_CONFIG}; do
        if [ "${@d.getVarFlags('UBOOT_DTB_NAME')}" = "None" ]; then
            UBOOT_DTB_NAME_FLAGS="${type}:${UBOOT_DTB_NAME}"
        else
            UBOOT_DTB_NAME_FLAGS="${@' '.join(flag + ':' + dtb for flag, dtb in (d.getVarFlags('UBOOT_DTB_NAME')).items()) if d.getVarFlags('UBOOT_DTB_NAME') is not None else '' }"
        fi

        for key_value in ${UBOOT_DTB_NAME_FLAGS}; do
            type_key="${key_value%%:*}"
            dtb_name="${key_value#*:}"

            if [ "$type_key" = "$type" ]
            then
                bbnote "UBOOT_CONFIG = $type, UBOOT_DTB_NAME = $dtb_name"

                UBOOT_CONFIG_EXTRA="$type_key"
                if [ -e ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${dtb_name}-${type} ] ; then
                    UBOOT_DTB_NAME_EXTRA="${dtb_name}-${type}"
                else
                    # backward compatibility
                    UBOOT_DTB_NAME_EXTRA="${dtb_name}"
                fi
                UBOOT_NAME_EXTRA="u-boot-${MACHINE}.bin-${UBOOT_CONFIG_EXTRA}"
                BOOT_CONFIG_MACHINE_EXTRA="${BOOT_NAME}-${MACHINE}-${UBOOT_CONFIG_EXTRA}.bin"

                for target in ${IMXBOOT_TARGETS}; do
                    compile_${SOC_FAMILY}
                    if [ "$target" = "flash_linux_m4_no_v2x" ]; then
                        # Special target build for i.MX 8DXL with V2X off
                        bbnote "building ${IMX_BOOT_SOC_TARGET} - ${REV_OPTION} V2X=NO ${target}"
                        make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} V2X=NO dtbs=${UBOOT_DTB_NAME_EXTRA} flash_linux_m4
                    else
                        bbnote "building ${IMX_BOOT_SOC_TARGET} - ${REV_OPTION} ${target}"
                        make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} dtbs=${UBOOT_DTB_NAME_EXTRA} ${target} > ${S}/hab_info1.txt 2>&1
                    fi

                    if [ "${HAB_ENABLE}" = "1" ];then
                        case ${MACHINE} in
                          "imx8mp-irma6r2")
                            print_cmd=print_fit_hab_ddr4
                            ;;
                          "imx8mp-lpddr4-evk")
                            print_cmd=print_fit_hab
                            ;;
                          *)
                            bberror "HAB signing is not supported yet for ${MACHINE}!"
                            ;;
                        esac
                        make SOC=iMX8MP $print_cmd > ${S}/hab_info2.txt
                    fi

                    if [ -e "${BOOT_STAGING}/flash.bin" ]; then
                        cp ${BOOT_STAGING}/flash.bin ${S}/${BOOT_CONFIG_MACHINE_EXTRA}-${target}
                    fi
                done

                unset UBOOT_CONFIG_EXTRA
                unset UBOOT_DTB_NAME_EXTRA
                unset UBOOT_NAME_EXTRA
                unset BOOT_CONFIG_MACHINE_EXTRA
            fi

            unset type_key
            unset dtb_name
        done

        unset UBOOT_DTB_NAME_FLAGS
    done
    unset type
}

#
# Emit the CSF File for SPL part
#
# $1 ... CSF SPL Filename
# $2 ... SRK Table Binary
# $3 ... CSF Key File
# $4 ... Image Key File
# $5 ... Block Data
# $6 ... CAAM / DCP
csf_emit_spl_file() {
	cat << EOF > ${1}
[Header]
Version = 4.5
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS
Engine = ${6}

[Install SRK]
File = "${2}"
Source index = 0

[Install CSFK]
File = "${3}"

[Authenticate CSF]

[Unlock]
Engine = ${6}
Features = MID

[Unlock]
Engine = ${6}
Features = MFG

[Install Key]
Verification index = 0
Target index = 2
File = "${4}"

[Authenticate Data]
Verification index = 2
Blocks = ${5}

EOF
}

#
# Emit the CSF File for FIT part
#
# $1 ... CSF FIT Filename
# $2 ... SRK Table Binary
# $3 ... CSF Key File
# $4 ... Image Key File
# $5 ... Block Data
# $6 ... CAAM / DCP
csf_emit_fit_file() {
	cat << EOF > ${1}
[Header]
Version = 4.5
Hash Algorithm = sha256
Engine = ${6}
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS

[Install SRK]
File = "${2}"
Source index = 0

[Install CSFK]
File = "${3}"

[Authenticate CSF]

[Unlock]
Engine = ${6}
Features = MID

[Unlock]
Engine = ${6}
Features = MFG

[Install Key]
Verification index = 0
Target index = 2
File = "${4}"

[Authenticate Data]
Verification index = 2
Blocks = ${5}

EOF
}

set_imxboot_vars() {
    for target in ${IMXBOOT_TARGETS}; do
        # Use first "target" as IMAGE_IMXBOOT_TARGET
        if [ "$IMAGE_IMXBOOT_TARGET" = "" ]; then
	        IMAGE_IMXBOOT_TARGET="$target"
        fi
    done
    BOOT_CONFIG_MACHINE_EXTRA="${BOOT_NAME}-${MACHINE}-${UBOOT_CONFIG}.bin"
}

sign_uboot_common() {
    # Copy flash.bin
    set_imxboot_vars
    fn="${S}/${BOOT_CONFIG_MACHINE_EXTRA}-${IMAGE_IMXBOOT_TARGET}.signed"
    cp ${S}/${BOOT_CONFIG_MACHINE_EXTRA}-${IMAGE_IMXBOOT_TARGET} ${fn}

    # Parse hab signing info (offset, blocks) 
    cst_off=$(cat ${S}/hab_info1.txt | grep -w csf_off | cut -f3)
    cst_off=$(hex2dec $cst_off)
    sld_csf_off=$(cat ${S}/hab_info1.txt | grep -w sld_csf_off | cut -f3)
    sld_csf_off=$(hex2dec $sld_csf_off)
    blocks_spl="$(cat ${S}/hab_info1.txt | grep -w "spl hab block" | cut -f2) \"${fn}\""
    blocks_fit1="$(cat ${S}/hab_info1.txt | grep -w "sld hab block" | cut -f2) \"${fn}\", \\"

    fit2_lines=${@bb.utils.contains('MACHINE_FEATURES', 'optee', '4', '3', d)}
    blocks_fit2="$(cat ${S}/hab_info2.txt | tail -n "$fit2_lines" | while read line; do echo "$line \"${fn}\", \\"; done)"
    blocks_fit=$(printf '%s\n%s' "$blocks_fit1" "${blocks_fit2%???}")

    # Create csf_spl.txt and csf_fit.txt
    csf_emit_spl_file "${S}/csf_spl.txt" "${SRKTAB}" "${CSFK}" "${SIGN_CERT}" "${blocks_spl}" "${CRYPTO_HW_ACCEL}"
    csf_emit_fit_file "${S}/csf_fit.txt" "${SRKTAB}" "${CSFK}" "${SIGN_CERT}" "${blocks_fit}" "${CRYPTO_HW_ACCEL}"

    # Create csf files
    cst -i ${S}/csf_spl.txt -o ${S}/csf_spl.bin
    cst -i ${S}/csf_fit.txt -o ${S}/csf_fit.bin

    # Sign bootable image
    dd if=${S}/csf_spl.bin of=$fn seek=$cst_off bs=1 conv=notrunc
    dd if=${S}/csf_fit.bin of=$fn seek=$sld_csf_off bs=1 conv=notrunc
}

do_sign_uboot() {
    if [ "${HAB_ENABLE}" = "1" ];then
        sign_uboot_common
    else
        bbwarn "HAB boot not enabled."
    fi
}

do_install:append() {
    if [ "${HAB_ENABLE}" = "1" ];then
        set_imxboot_vars
        install -m 0644 ${S}/${BOOT_CONFIG_MACHINE_EXTRA}-${IMAGE_IMXBOOT_TARGET}.signed ${D}/boot/
    fi
}

do_deploy:append() {
    if [ "${HAB_ENABLE}" = "1" ];then
        # copy flash.bin.signed to deploy dir and create a symlink imx-boot.signed
        set_imxboot_vars
        install -m 0644 ${S}/${BOOT_CONFIG_MACHINE_EXTRA}-${IMAGE_IMXBOOT_TARGET}.signed ${DEPLOYDIR}
        cd ${DEPLOYDIR}
        ln -sf ${BOOT_CONFIG_MACHINE_EXTRA}-${IMAGE_IMXBOOT_TARGET}.signed ${BOOT_NAME}.signed
        cd -
    fi
}

addtask do_sign_uboot before do_deploy do_install after do_compile
