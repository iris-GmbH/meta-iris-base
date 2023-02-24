# SPDX-License-Identifier: MIT
# Copyright (C) 2021-2022 iris-GmbH infrared & intelligent sensors

inherit irma6-bootloader-version
LOCALVERSION = "-${IRIS_IMX_BOOT_RELEASE}"

UBOOT_INITIAL_ENV = "u-boot-initial-env"

FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-imx/common:"
SRC_URI:append = "\
	file://fw_env.config \
	file://0001-env-Fix-prio-on-bad-CRC-case-with-ENV_APPEND-enabled.patch \
	file://0002-env-Invert-gd-env_valid-for-env_mmc_save.patch \
	file://0003-imx8m-soc.c-Use-arch-specific-env_get_location.patch \
	file://0004-Add-HAB-image-authentication-for-FIT-Images.patch \
	file://0005-crypto-caam-Add-fsl-caam-driver.patch \
	file://0006-MLK-19053-crypto-caam-RNG4-TRNG-errata.patch \
"

FILESEXTRAPATHS:prepend:imx8mpevk := "${THISDIR}/u-boot-imx/imx8mpevk:"
SRC_URI:append:imx8mpevk = "\
	file://0001-Use-partition-labels-in-environment-and-auto-detect-.patch \
	file://0002-imx8mp-evk-Enable-secure-boot-and-FIT-image-support.patch \
	file://0003-Remove-CONFIG_CMD_BOOTEFI-for-imx8mp_evk_defconfig.patch \
	file://0004-imx8mp-evk-Add-cmd-for-booting-signed-fitImage.patch \
	file://0005-imx8mp-evk-Change-bootcmd-to-fitboot.patch \
	file://0006-Add-redundand-env-support.patch \
"

FILESEXTRAPATHS:prepend:imx8mp-irma6r2 := "${THISDIR}/u-boot-imx/imx8mp-irma6r2:"
SRC_URI:append:imx8mp-irma6r2 = "\
	file://0001-imx8mp_irma6r2_defconfig-Copy-defconfig.patch \
	file://0002-imx8mp_irma6_defconfig-Adapt-defconfig-to-our-needs.patch \
	file://0003-imx8mp_irma6r2-Copy-device-tree-files.patch \
	file://0004-imx8mp-irma6r2-Adapt-device-tree-files-to-our-needs.patch \
	file://0005-imx8mp-irma6r2-Copy-board-support-files-for-irma6r2.patch \
	file://0006-imx8mp-irma6r2-Adapt-board-support-files-for-irma6r2.patch \
	file://0007-eqos-Make-generic-EQOS-driver-usable-for-RMII.patch \
	file://0008-imx8mp-irma6r2-Add-IU-EEPROM-readout-for-configuring.patch \
	file://0009-imx8mp-irma6r2-Add-check-for-when-the-device-is-lock.patch \
"

SRC_URI:append:poky-iris-deploy = "\
	file://deploy-u.cfg \
"
