# SPDX-License-Identifier: MIT
# Copyright (C) 2021-2024 iris-GmbH infrared & intelligent sensors

inherit irma6-bootloader-version
LOCALVERSION = "-${IRIS_IMX_BOOT_RELEASE}"

UBOOT_INITIAL_ENV = "u-boot-initial-env"

FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-imx:"
SRC_URI:append = "\
	file://fw_env.config \
	file://0001-Add-HAB-image-authentication-for-FIT-Images.patch \
	file://0002-crypto-caam-Add-fsl-caam-driver.patch \
	file://0003-MLK-19053-crypto-caam-RNG4-TRNG-errata.patch \
	file://0004-imx8mp_irma6r2-Copy-imx8mp-irma6r2-boardfiles.patch \
	file://0005-Adapt-imx8mp-irma6r2-board-files-to-our-needs.patch \
	file://0006-imx8mp-irma6r2-Add-IU-EEPROM-readout-for-configuring.patch \
	file://0007-imx8mp-irma6r2-Add-check-for-when-the-device-is-lock.patch \
	file://0008-Update-imx8mp-evk-board-files-for-our-needs.patch \
	file://0009-Adapt-imx93evk-board-files-for-Matrix-UP.patch \
	file://0010-Add-AHAB-Support-for-kernel-fitImages.patch \
	file://0011-Copy-imx93-matrixup-board-files-and-devicetree.patch \
	file://0012-Adapt-imx93-matrixup-board-files.patch \
	file://0013-Force-ethernet-PHY-DP83825-into-slave-mode.patch \
	file://0014-usb-ci_udc-Implement-errata-workaround-for-ERR051725.patch \
	file://0015-net-dwc_eth_qos-Add-support-for-platform-specific-re.patch \
	file://0016-net-dwc_eth_qos_imx-Add-platform-specific-reset-for-.patch \
	file://0017-soc-Add-RAM-Test-get_ram_size.patch \
	file://0018-imx8mp_irma6r2-add-support-for-fitImage-configuratio.patch \
	file://0019-imx93_matrixup-Implement-device-locking-via-uboot-en.patch \
	file://0020-imx93_matrixup-Populate-lifecycle-state-via-uboot-en.patch \
	file://0021-ddr_init-Allow-repeated-init-and-provide-MR8-registe.patch \
	file://0022-imx93_matrixup-Select-DDR-timing-file-based-on-MR8-r.patch \
	file://0023-imx8mp_irma6r2.c-Fix-possible-nfsboot-persistent-fai.patch \
	file://0024-imx93_matrixup.c-Fix-possible-nfsboot-persistent-fai.patch \
	file://0025-net-phy-micrel-Introduce-devicetree-options.patch \
	file://0026-imx93-matrixup-Support-KSZ8081-ethernet-PHY.patch \
	file://0027-Remove-warning-Bad-device-specification.patch \
"

SRC_URI:append:poky-iris-deploy = "\
	file://deploy-u.cfg \
"
