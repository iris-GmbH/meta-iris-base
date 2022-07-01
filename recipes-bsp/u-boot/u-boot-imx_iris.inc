# SPDX-License-Identifier: MIT
# Copyright (C) 2021-2022 iris-GmbH infrared & intelligent sensors

UBOOT_INITIAL_ENV = "u-boot-initial-env"

FILESEXTRAPATHS_prepend := "${THISDIR}/u-boot-imx/common:"
SRC_URI_append = "\
	file://0001-Backport-cmd-fs-Use-part_get_info_by_dev_and_name_or.patch\
	file://0002-Backport-part-Give-several-functions-more-useful-ret.patch\
	file://0003-Add-HAB-image-authentication-for-FIT-Images.patch \
	file://0004-MLK-23089-crypto-fsl_caam-add-rng-prediction-resista.patch \
	file://0005-env-Warn-on-force-access-if-ENV_ACCESS_IGNORE_FORCE-.patch \
	file://0006-env-Add-H_DEFAULT-flag.patch \
	file://0007-env-Discern-environment-coming-from-external-storage.patch \
	file://0008-env-Add-option-to-only-ever-append-environment.patch \
	file://0009-env-Add-support-for-explicit-write-access-list.patch \
	file://0010-env-nowhere-add-.load-ops.patch \
	file://0011-env-Fix-warning-when-forcing-environment-without-ENV.patch \
	file://0012-env-split-env_import_redund-into-2-functions.patch \
	file://0013-env-increment-redund-flag-on-read-fail.patch \
	file://0014-env-Fix-invalid-env-handling-in-env_init.patch \
	file://0015-env-Fix-prio-on-bad-CRC-case-with-ENV_APPEND-enabled.patch \
	file://0016-env-Invert-gd-env_valid-for-env_mmc_save.patch \
	file://0017-imx8m-soc.c-Use-arch-specific-env_get_location.patch \
"

FILESEXTRAPATHS_prepend_imx8mpevk := "${THISDIR}/u-boot-imx/imx8mpevk:"
SRC_URI_append_imx8mpevk = "\
	file://0001-Use-partition-labels-in-environment-and-auto-detect-.patch\
	file://0002-imx8mp-evk-Enable-secure-boot-and-FIT-image-support.patch \
	file://0003-RDPHOEN-958-Remove-CONFIG_CMD_BOOTEFI-for-imx8mp_evk.patch \
	file://0004-imx8mp-evk-Add-cmd-for-booting-signed-fitImage.patch \
	file://0005-imx8mp-evk-Change-bootcmd-to-fitboot.patch \
	file://0006-imx8mp-evk-Increase-CONFIG_SYS_BOOTM_LEN-to-32MB.patch \
	file://0007-imx8mp-evk-defconfig-Use-redundand-env-support.patch \
	file://0008-imx8mp-evk-Resorting-imx8mp_evk_defconfig.patch \
	file://0009-imx8mp-evk-Implementing-bootcount_limit.patch \
	file://0010-imx8mp_evk.h-Introduce-netfitboot-command.patch \
	file://0011-imx8mpevk-Add-reset-after-bootcmd.patch \
	file://0012-imx8mp-evk-Add-CONFIG_ENV_FLAGS_LIST_STATIC.patch \
	file://0013-imx8mp_evk_defconfig-Configure-writeable-list-suppor.patch \
"

FILESEXTRAPATHS_prepend_imx8mp-irma6r2 := "${THISDIR}/u-boot-imx/imx8mp-irma6r2:"
SRC_URI_append_imx8mp-irma6r2 = "\
	file://0001-Create-board-support-files-for-irma6r2.patch \
	file://0002-Add-defconfig-file-for-irma6r2.patch \
	file://0003-Add-device-tree-imx8mp-irma6r2.dts-for-irma6-release.patch \
	file://0004-Set-model-and-license.patch \
	file://0005-ddr4-update-training-timing-files-for-1600MHz-and-53.patch \
	file://0006-Customize-imx8mp_irma6r2_defconfig.patch \
	file://0007-mmc-MMC-is-connected-to-slot-2.patch \
	file://0008-Move-pmic-from-i2c1-to-i2c3.patch \
	file://0009-Set-DRAM-size-to-1x512MiB.patch \
	file://0010-Enable-UART3-and-UART4.patch \
	file://0011-Disable-fec-node-for-irma6r2.patch \
	file://0012-Setup-eqos-for-RMII.patch \
	file://0013-Use-partition-labels-in-environment-and-auto-detect-.patch \
	file://0014-imx8mp-irma6r2-Enable-Secure-Boot-and-FIT-Image-supp.patch \
	file://0015-RDPHOEN-958-Remove-CONFIG_CMD_BOOTEFI-for-imx8mp_irm.patch \
	file://0016-imx8mp-irma6r2-Add-cmd-for-booting-signed-fitImage.patch \
	file://0017-imx8mp-irma6r2-Increase-CONFIG_SYS_BOOTM_LEN-to-32MB.patch \
	file://0018-imx8mp-irma6r2-Change-bootcmd-to-fitboot.patch \
	file://0019-imx8mp-irma6r2-defconfig-Use-redundand-env-support.patch \
	file://0020-imx8mp-irma6r2-Implementing-bootcount_limit-for-irma6r2.patch \
	file://0021-imx8mp_irma6r2.h-Introduce-netfitboot-command.patch \
	file://0022-imx8mp-irma6r2-Add-CONFIG_ENV_FLAGS_LIST_STATIC.patch \
	file://0023-imx8mp-irma6r2-Add-reset-after-bootcmd.patch \
	file://0024-imx8mp_irma6r2_defconfig-Configure-writeable-list-su.patch \
    file://0025-imx8mp_irma6r2-Generic-EQOS-driver-dwc_eth_qos.c-usable-for-RMII.patch \
"
