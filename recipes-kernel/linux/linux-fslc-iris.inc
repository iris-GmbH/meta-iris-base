# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/linux-fslc-iris:"

SRC_URI += " \
    file://imx8mp-evk-r2_defconfig \
    file://imx8mp_irma6r2_defconfig \
    file://0001-epc660-Add-device-driver-support.patch \
    file://0002-tc358746-Add-device-driver-support.patch \
    file://0003-imx8mp-evk.dts-Add-epc660-and-tc358746-nodes-to-dts.patch \
    file://0004-Bugfix-Ignore-CQE-flag-in-sdhci-esdhc-imx-driver.patch \
    file://0005-i2c-imx-remove-unneeded-sleep.patch \
    file://0006-Bugfix-Save-csis-format-to-internal-structure-of-imx.patch \
    file://0007-imx8-isi-cap-Add-V4L2_PIX_FMT_SBGGR12-Raw12-and-V4L2.patch \
    file://0008-imx8-isi-core.h-Add-MXC_ISI_OUT_FMT_RAW14-enum.patch \
    file://0009-imx8-mipi-cs2-sam-Add-Raw12-and-Raw14-formats.patch \
    file://0010-mipi-csi2-sam-fix-MEDIA-MIX-gasket0-dumps.patch \
    file://0011-imx8-media-dev-fix-source-sink-pad-setup.patch \
    file://0012-Hack-imx8-media-dev-Disable-unregistering-of-mxc_isi.patch \
    file://0013-Add-imx8mp-irma6r2-devicetree.patch \
    file://0014-imx8mp-irma6r2.dts-Add-epc660-and-tc358746-nodes.patch \
    file://0015-imx8mp-irma6r2.dts-Reduce-size-of-linux-cma-contiguo.patch \
    file://0016-imx8mp-irma6r2.dts-Move-pca9450-pmic-from-i2c1-to-i2.patch \
    file://0017-imx8mp-irma6r2.dts-Set-LED-to-correct-GPIO.patch \
    file://0018-imx8mp-irma6r2.dts-Remove-USB1-and-set-USB0-to-micro.patch \
    file://0019-imx8mp-irma6r2.dts-Set-the-correct-GPIO-to-reset-epc.patch \
    file://0020-imx8mp-irma6r2.dts-Replace-dummy-clock-for-serialize.patch \
    file://0021-imx8mp-irma6r2.dts-Set-i2c-to-max-frequency-and-enab.patch \
    file://0022-imx8mp-irma6r2.dts-Add-support-for-the-PCF8563TS-RTC.patch \
    file://0023-imx8mp-irma6r2.dts-Enable-i2c-port-expander-pca9554-.patch \
    file://0024-imx8mp-irma6r2.dts-Disable-UART1.patch \
    file://0025-imx8mp-irma6r2.dts-Configure-UART3-and-UART4.patch \
    file://0026-imx8mp-irma6r2.dts-Add-lm75-sensor-to-i2c2.patch \
    file://0027-imx8mp-irma6r2.dts-Add-WAKEUP-GPIO-key-as-wakeup-sou.patch \
    file://0028-imx8mp-irma6r2.dts-change-board-model-name.patch \
    file://0029-imx8mp-irma6r2.dts-Disable-eqos-and-fec-ethernet-nod.patch \
    file://0030-imx8mp-irma6r2.dts-Set-DRAM-size-to-1x512MiB.patch \
    file://0031-tc358746.c-Reset-when-changing-format.patch \
    file://0032-imx8mp-irma6r2.dts-Change-memory-range-for-dsp.patch \
"

KERNEL_DEFCONFIG_imx8mpevk = "imx8mp-evk-r2_defconfig"
KERNEL_DEFCONFIG_imx8mp-irma6r2 = "imx8mp_irma6r2_defconfig"

# Don't include kernels in standard images
RDEPENDS_${KERNEL_PACKAGE_NAME}-base = ""
