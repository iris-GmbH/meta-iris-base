# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

require uuu-container.inc
FLASHBIN:imx8mp-lpddr4-evk = "boot/imx-boot-imx8mp-lpddr4-evk-sd.bin-flash_evk.signed"
FLASHBIN:imx8mp-irma6r2 = "boot/imx-boot-imx8mp-irma6r2-sd.bin-flash_ddr4_evk.signed"
FLASHBIN:imx93-11x11-lpddr4x-evk = "boot/imx-boot-imx93-11x11-lpddr4x-evk-sd.bin-flash_singleboot.signed"

UUUSCRIPT:mx8mp-nxp-bsp = "flashall_imx8mp.uuu"
UUUSCRIPT:imx93-11x11-lpddr4x-evk = "flashall_imx93evk.uuu"

VERIFICATIONSCRIPT:mx8mp-nxp-bsp = "verification_imx8mp.sh"
VERIFICATIONSCRIPT:imx93-11x11-lpddr4x-evk = "verification_imx93evk.sh"

# only allow iMX machines
COMPATIBLE_MACHINE = "(mx8mp-nxp-bsp|mx93-nxp-bsp)"

# the CAAM driver seems to have a bug when the kernel runs with more than 4 GB of RAM
# see: https://community.nxp.com/t5/i-MX-Processors/quot-swiotlb-buffer-is-full-quot-when-writing-large-file-on/m-p/1586218
# this append inserts a "mem=3072M" into the uuu mfgtool bootargs (instead of splitting the flashall.uuu into machine specific folders)
do_deploy:append:imx8mp-lpddr4-evk() {
    head -n15 ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY} > ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}.tmp
    echo 'FB: ucmd setenv bootargs console=${console},${baudrate} rdinit=/linuxrc clk_ignore_unused mem=3072M' >> ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}.tmp
    tail -n +16 ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY} >> ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}.tmp
    mv ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}.tmp ${UUU_DEPLOY_DIR}/${UUUSCRIPTDEPLOY}
}
