# SPDX-License-Identifier: MIT
# Copyright (C) 2021-2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend_imx8mpevk := "${THISDIR}/${BPN}/imx8mpevk:"
SRC_URI_append_imx8mpevk = "\
	file://0001-Backport-cmd-fs-Use-part_get_info_by_dev_and_name_or.patch\
	file://0002-Backport-part-Give-several-functions-more-useful-ret.patch\
	file://0003-Use-partition-labels-in-environment-and-auto-detect-.patch\
"

FILESEXTRAPATHS_prepend_imx8mpirma6r2 := "${THISDIR}/${BPN}/imx8mpirma6r2:"
SRC_URI_append_imx8mpirma6r2 = "\
	file://0001-Create-board-support-files-for-irma6r2.patch \
	file://0002-Add-defconfig-file-for-irma6r2.patch \
	file://0003-Add-device-tree-imx8mp-irma6r2.dts-for-irma6-release.patch \
	file://0004-Set-model-and-license.patch \
	file://0005-ddr4-update-training-timing-files-for-1600MHz-and-53.patch \
	file://0006-Customize-imx8mp_irma6r2_defconfig.patch \
	file://0007-mmc-MMC-is-connected-to-slot-2.patch \
	file://0008-Move-pmic-from-i2c1-to-i2c3.patch \
	file://0009-Set-DRAM-size-to-1x1GiB.patch \
	file://0010-Enable-UART3-and-UART4.patch \
	file://0011-Disable-fec-node-for-irma6r2.patch \
	file://0012-Setup-eqos-for-RMII.patch \
	file://0013-Backport-cmd-fs-Use-part_get_info_by_dev_and_name_or.patch \
	file://0014-Backport-part-Give-several-functions-more-useful-ret.patch \
	file://0015-Use-partition-labels-in-environment-and-auto-detect-.patch \
"
