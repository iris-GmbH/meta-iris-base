# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-fslc-iris:"

SRC_URI += " \
    file://0001-epc660-Add-device-driver-support.patch \
    file://0002-tc358746-Add-device-driver-support.patch \
    file://0003-imx8mp-evk.dts-Add-epc660-and-tc358746-nodes-to-dts.patch \
    file://0004-i2c-imx-remove-unneeded-sleep.patch \
    file://0005-imx8-isi-cap-Add-V4L2_PIX_FMT_SBGGR12-Raw12-and-V4L2.patch \
    file://0006-imx8-isi-core.h-Add-MXC_ISI_OUT_FMT_RAW14-enum.patch \
    file://0007-imx8-mipi-cs2-sam-Add-Raw12-and-Raw14-formats.patch \
    file://0008-mipi-csi2-sam-fix-MEDIA-MIX-gasket0-dumps.patch \
    file://0009-imx8-media-dev-fix-source-sink-pad-setup.patch \
    file://0010-Add-imx8mp-irma6r2-devicetree.patch \
    file://0011-imx8mp-irma6r2.dts-Add-epc660-and-tc358746-nodes.patch \
    file://0012-imx8mp-irma6r2.dts-Reduce-size-of-linux-cma-contiguo.patch \
    file://0013-imx8mp-irma6r2.dts-Move-pca9450-pmic-from-i2c1-to-i2.patch \
    file://0014-imx8mp-irma6r2.dts-Set-LED-to-correct-GPIO.patch \
    file://0015-imx8mp-irma6r2.dts-Remove-USB1-and-set-USB0-to-micro.patch \
    file://0016-imx8mp-irma6r2.dts-Set-the-correct-GPIO-to-reset-epc.patch \
    file://0017-imx8mp-irma6r2.dts-Replace-dummy-clock-for-serialize.patch \
    file://0018-imx8mp-irma6r2.dts-Set-i2c-to-max-frequency-and-enab.patch \
    file://0019-imx8mp-irma6r2.dts-Add-support-for-the-PCF8563TS-RTC.patch \
    file://0020-imx8mp-irma6r2.dts-Enable-i2c-port-expander-pca9554-.patch \
    file://0021-imx8mp-irma6r2.dts-Disable-UART1.patch \
    file://0022-imx8mp-irma6r2.dts-Configure-UART3-and-UART4.patch \
    file://0023-imx8mp-irma6r2.dts-Add-lm75-sensor-to-i2c2.patch \
    file://0024-imx8mp-irma6r2.dts-Add-WAKEUP-GPIO-key-as-wakeup-sou.patch \
    file://0025-imx8mp-irma6r2.dts-change-board-model-name.patch \
    file://0026-imx8mp-irma6r2.dts-Setup-eqos-and-remove-fec-node.patch \
    file://0027-imx8mp-irma6r2.dts-Set-DRAM-size-to-1x512MiB.patch \
    file://0028-tc358746.c-Reset-when-changing-format.patch \
    file://0029-imx8mp-irma6r2.dts-Change-memory-range-for-dsp.patch \
    file://0030-rtc-pcf8563-Skip-registering-of-clkout-for-RTC.patch \
    file://0031-imx8mp-irma6r2.dts-Adjust-EPC660-TC358746-reset-pins.patch \
    file://0032-Increase-critical-thermal-point.patch \
    file://0033-Fix-MIPI-settings-on-tc358746.patch \
    file://0034-imx8mp-evk.dts-Serializer-config.patch \
    file://0035-imx8mp-irma6r2.dts-Serializer-config.patch \
    file://0036-epc660-respect-reset-timings.patch \
"

SRC_URI:append:poky-iris-deploy = "\
	file://deploy.cfg \
"

# Don't include kernels in standard images
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""
