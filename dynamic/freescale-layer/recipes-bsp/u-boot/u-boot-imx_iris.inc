# SPDX-License-Identifier: MIT
# Copyright (C) 2021-2022 iris-GmbH infrared & intelligent sensors

inherit irma6-bootloader-version
LOCALVERSION = "-${IRIS_IMX_BOOT_RELEASE}"

UBOOT_INITIAL_ENV = "u-boot-initial-env"

FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-imx/common:"
SRC_URI:append:mx8mp-nxp-bsp = "\
	file://0001-Add-HAB-image-authentication-for-FIT-Images.patch \
	file://0002-crypto-caam-Add-fsl-caam-driver.patch \
	file://0003-MLK-19053-crypto-caam-RNG4-TRNG-errata.patch \
"

FILESEXTRAPATHS:prepend:imx8mp-lpddr4-evk := "${THISDIR}/u-boot-imx/imx8mp-lpddr4-evk:"
SRC_URI:append:imx8mp-lpddr4-evk = "\
	file://fw_env.config \
	file://0001-Use-partition-labels-in-environment-and-auto-detect-.patch \
	file://0002-Update-imx8mp_evk_defconfig.patch \
	file://0003-imx8mp-evk-Enable-secure-boot-and-FIT-image-support.patch \
	file://0004-Remove-CONFIG_CMD_BOOTEFI-for-imx8mp_evk_defconfig.patch \
	file://0005-imx8mp-evk-Add-cmd-for-booting-signed-fitImage.patch \
	file://0006-imx8mp-evk-Change-bootcmd-to-fitboot.patch \
	file://0007-Add-redundand-env-support.patch \
	file://0008-Disable-CONFIG_EFI_LOADER-and-CONFIG_CMD_DFU-to-fix-.patch \
"

FILESEXTRAPATHS:prepend:imx8mp-irma6r2 := "${THISDIR}/u-boot-imx/imx8mp-irma6r2:"
SRC_URI:append:imx8mp-irma6r2 = "\
	file://fw_env.config \
	file://0001-imx8mp_irma6r2-Copy-device-tree-files.patch \
	file://0002-imx8mp-irma6r2-Adapt-device-tree-files-to-our-needs.patch \
	file://0003-imx8mp-irma6r2-Copy-board-support-files-for-irma6r2.patch \
	file://0004-imx8mp-irma6r2-Adapt-board-support-files-for-irma6r2.patch \
	file://0005-imx8mp_irma6r2_defconfig-Copy-defconfig.patch \
	file://0006-imx8mp_irma6r2_defconfig-Adapt-defconfig-to-our-need.patch \
	file://0007-imx8mp-irma6r2-Add-IU-EEPROM-readout-for-configuring.patch \
	file://0008-imx8mp-irma6r2-Add-check-for-when-the-device-is-lock.patch \
	file://0009-imx8mp-irma6r2-Set-lpj-32000.patch \
	file://0010-imx8mp_irma6r2-Use-UART-3-for-debug-output.patch \
	file://0011-imx8mp-irma6r2.dts-Set-eqos-to-rmii-clock-rate.patch \
"

FILESEXTRAPATHS:prepend:imx93-11x11-lpddr4x-evk := "${THISDIR}/u-boot-imx/imx93-11x11-lpddr4x-evk:"
SRC_URI:append:imx93-11x11-lpddr4x-evk = "\
	file://fw_env.config \
	file://0001-Adapt-imx93evk-for-fitImage-boot.patch \
	file://0002-Add-AHAB-Support-for-imx93evk.patch \
	file://0003-Use-ext4load-instead-of-fatload-partitions.patch \
	file://0004-defconfig-bootcount-and-env-adaptions.patch \
	file://0005-imx93_evk.h-Restrict-uboot-env-s-by-CONFIG_ENV_WRITE.patch \
"

FILESEXTRAPATHS:prepend:imx93-matrixup := "${THISDIR}/u-boot-imx/imx93-matrixup:"
SRC_URI:append:imx93-matrixup = "\
	file://fw_env.config \
	file://0001-Adapt-imx93evk-for-fitImage-boot.patch \
	file://0002-Add-AHAB-Support-for-imx93evk.patch \
	file://0003-Use-ext4load-instead-of-fatload-partitions.patch \
	file://0004-defconfig-bootcount-and-env-adaptions.patch \
	file://0005-imx93_evk.h-Restrict-uboot-env-s-by-CONFIG_ENV_WRITE.patch \
	file://0006-Copy-imx93-matrixup-board-files-and-devicetree.patch \
	file://0007-Rename-Kconfig-for-imx93_matrixup.patch \
	file://0008-Copy-include-configs-imx93_matrixup.h-from-imx93_evk.patch \
	file://0009-Modify-include-configs-imx93_matrixup.h.patch \
	file://0010-Copy-imx93_matrixup_defconfig-from-imx93-evk.patch \
	file://0011-Modify-imx93_matrixup_defconfig.patch \
	file://0012-imx93-matrixup.dts-Remove-fec-node.patch \
	file://0013-imx93-matrixup.dts-Move-pmic-to-i2c1.patch \
	file://0014-imx93-matrixup.dts-Remove-mipi-dsi-stuff.patch \
	file://0015-imx93-matrixup.dts-Disable-display-controller.patch \
	file://0016-imx93-matrixup.dts-Remove-support-for-keypad-decoder.patch \
	file://0017-imx93-matrixup.dts-Remove-support-for-the-pcf2131-RT.patch \
	file://0018-imx93-matrixup.dts-Use-gpio3_io20-for-pmic-interrupt.patch \
	file://0019-imx93-matrixup.dts-Remove-Port-Expander-pcal6524.patch \
	file://0020-imx93-matrixup.dts-Set-board-model-name.patch \
	file://0021-imx93-matrixup.dts-Remove-rtc0-alias.patch \
	file://0022-Copy-imx93-matrixup-u-boot.dtsi-from-imx93-11x11-evk.patch \
	file://0023-Modify-imx93-matrixup-u-boot.dtsi.patch \
	file://0024-imx93-matrixup.dts-Remove-USB-TypeC-nodes.patch \
	file://0025-Remove-typec-setup-from-imx93_matrixup.c.patch \
	file://0026-imx93-matrixup.dts-Configure-Eth-Phy-EQOS-node-for-R.patch \
	file://0027-imx93_matrixup.c-Remove-fec-clock-setup.patch \
	file://0028-Fix-i.MX93-eqos-quirk-by-configuring-the-speed-durin.patch \
	file://0029-Force-ethernet-PHY-DP83825-into-slave-mode.patch \
	file://0030-WIP-use-lower-speed-RAM-configuration.patch \
	file://0031-usb-ci_udc-Implement-errata-workaround-for-ERR051725.patch \
	file://0032-WIP-disable-HS400-support-to-fix-communication-with-.patch \
"

SRC_URI:append:poky-iris-deploy = "\
	file://deploy-u.cfg \
"
