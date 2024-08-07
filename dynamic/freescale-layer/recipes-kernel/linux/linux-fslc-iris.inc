# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-fslc-iris:"

# Unset in-tree defconfig and use local defconfig
KBUILD_DEFCONFIG:mx8-generic-bsp = ""
KBUILD_DEFCONFIG:mx9-generic-bsp = ""

SRC_URI:append = " \
    file://defconfig \
"

# irma6r2 specific patches
SRC_URI:append:mx8mp-nxp-bsp = " \
  file://0001-epc660-Add-device-driver-support.patch \
  file://0002-imx8mp-evk.dts-Add-epc660-and-tc358746-nodes-to-dts.patch \
  file://0003-i2c-imx-remove-unneeded-sleep.patch \
  file://0004-imx8-isi-cap-Add-V4L2_PIX_FMT_SBGGR12-Raw12-and-V4L2.patch \
  file://0005-imx8-isi-core.h-Add-MXC_ISI_OUT_FMT_RAW14-enum.patch \
  file://0006-imx8-mipi-cs2-sam-Add-Raw12-and-Raw14-formats.patch \
  file://0007-mipi-csi2-sam-fix-MEDIA-MIX-gasket0-dumps.patch \
  file://0008-imx8-media-dev-fix-source-sink-pad-setup.patch \
  file://0009-Add-imx8mp-irma6r2-devicetree.patch \
  file://0010-imx8mp-irma6r2.dts-Add-epc660-and-tc358746-nodes.patch \
  file://0011-imx8mp-irma6r2.dts-Reduce-size-of-linux-cma-contiguo.patch \
  file://0012-imx8mp-irma6r2.dts-Move-pca9450-pmic-from-i2c1-to-i2.patch \
  file://0013-imx8mp-irma6r2.dts-Set-LED-to-correct-GPIO.patch \
  file://0014-imx8mp-irma6r2.dts-Remove-USB1-and-set-USB0-to-micro.patch \
  file://0015-imx8mp-irma6r2.dts-Set-the-correct-GPIO-to-reset-epc.patch \
  file://0016-imx8mp-irma6r2.dts-Replace-dummy-clock-for-serialize.patch \
  file://0017-imx8mp-irma6r2.dts-Set-i2c-to-max-frequency-and-enab.patch \
  file://0018-imx8mp-irma6r2.dts-Add-support-for-the-PCF8563TS-RTC.patch \
  file://0019-imx8mp-irma6r2.dts-Enable-i2c-port-expander-pca9554-.patch \
  file://0020-imx8mp-irma6r2.dts-Disable-UART1.patch \
  file://0021-imx8mp-irma6r2.dts-Configure-UART3-and-UART4.patch \
  file://0022-imx8mp-irma6r2.dts-Add-lm75-sensor-to-i2c2.patch \
  file://0023-imx8mp-irma6r2.dts-Add-WAKEUP-GPIO-key-as-wakeup-sou.patch \
  file://0024-imx8mp-irma6r2.dts-change-board-model-name.patch \
  file://0025-imx8mp-irma6r2.dts-Setup-eqos-and-remove-fec-node.patch \
  file://0026-imx8mp-irma6r2.dts-Set-DRAM-size-to-1x512MiB.patch \
  file://0027-imx8mp-irma6r2.dts-Change-memory-range-for-dsp.patch \
  file://0028-rtc-pcf8563-Skip-registering-of-clkout-for-RTC.patch \
  file://0029-imx8mp-irma6r2.dts-Adjust-EPC660-TC358746-reset-pins.patch \
  file://0030-Increase-critical-thermal-point.patch \
  file://0031-imx8-mipi-csi2-sam.c-Add-debug-1.patch \
  file://0032-imx8mp-evk.dts-Serializer-config.patch \
  file://0033-imx8mp-irma6r2.dts-Serializer-config.patch \
  file://0034-epc660-respect-reset-timings.patch \
  file://0035-imx8mp-evk.dts-imx8mp-irma6r2.dts-Disable-VPU-GPU.patch \
  file://0036-lm75.c-Defer-probe-if-i2c-communication-fails-with-E.patch \
  file://0037-epc660-reload-fw-after-hw-reset.patch \
  file://0038-EPC660-Update-sequencer-code-to-V14-Datasheet-V2.20.patch \
  file://0039-epc660-remove-the-register-setting-of-EPC660_REG_LED.patch \
  file://0040-Set-VB2_MAX_FRAME-VIDEO_MAX_FRAME-up-to-128-from-for.patch \
  file://0041-i2c-imx-Introduce-optional-busy-polling-for-xfer.patch \
  file://0042-imx8mp-irma6r2.dts-Use-UART3-for-debug-output.patch \
  file://0043-imx8mp-irma6r2.dts-Adapt-for-kernel-6.6.patch \
  file://0044-imx8-media-dev-Remove-check-and-removal-in-probe.patch \
  file://0045-media-tc358746-fix-the-pll-calculating-function.patch \
  file://0046-epc660.c-Add-link-frequency-v4l2_ctrl.patch \
  file://0047-tc358746.c-Move-vb-size-calculation-to-seperate-func.patch \
  file://0048-tc358746.c-Add-RAW12-to-format-list.patch \
  file://0049-tc358746.c-Add-empty-s_power-and-link_setup-function.patch \
  file://0050-tc358746.c-Remove-MEDIA_LNK_FL_IMMUTABLE.patch \
  file://0051-imx8-isi-cap.c-Pass-correct-format-to-subdev.patch \
  file://0052-tc358746.c-Implement-hsync-vsync-polarity-config.patch \
"

# irma-matrix specific patches
SRC_URI:append:mx93-nxp-bsp = " \
  file://0001-media-i2c-Add-marec-fpga-camera-driver.patch \
  file://0002-dts-freescale-Add-imx93-evk-devicetree-with-marec-ca.patch \
  file://0003-media-imx-Fix-parallel-camera-and-media-drivers.patch \
  file://0004-media-imx-Add-RAW8-and-RAW10-format-and-default-to-R.patch \
  file://0005-fpga-xilinx-spi-Make-DONE-gpio-optional.patch \
  file://0006-LF-10512-media-imx-ci_pi-fix-green-line-at-frame-bot.patch \
"

KERNEL_DEVICETREE:append:mx93-nxp-bsp = " freescale/${KERNEL_DEVICETREE_BASENAME}-marec-fpga.dtb"

SRC_URI:append:poky-iris-deploy = "\
	file://deploy.cfg \
"

# Don't include kernels in standard images
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""
