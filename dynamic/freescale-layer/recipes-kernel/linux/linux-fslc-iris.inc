# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-fslc-iris:"

# Unset in-tree defconfig and use local defconfig
KBUILD_DEFCONFIG:mx8-generic-bsp = ""
KBUILD_DEFCONFIG:mx9-generic-bsp = ""

SRC_URI:append = " \
    file://defconfig \
"

SRC_URI:append = " \
    file://0001-media-i2c-Add-marec-fpga-camera-driver.patch \
    file://0002-fpga-xilinx-spi-Make-DONE-gpio-optional.patch \
    file://0003-dts-freescale-Add-imx93-evk-devicetree-with-marec-ca.patch \
    file://0004-imx8-isi-cap.c-Allow-format-code-propagation-and-add.patch \
    file://0005-imx8-isi-hw.c-Do-not-set-RAW-to-MSB-align-reserved-b.patch \
    file://0006-imx8-parallel-csi.c-Fix-missing-first-frames-and-for.patch \
    file://0007-imx8-isi-fmt.c-Add-RAW8-RAW10-RAW12-and-RAW14-format.patch \
    file://0008-imx8-isi-core.h-Add-MXC_ISI_OUT_FMT_RAW14-enum.patch \
    file://0009-imx8-mipi-cs2-sam-Add-Raw12-and-Raw14-formats.patch \
    file://0010-imx8-media-dev-fix-source-sink-pad-setup-and-probing.patch \
    file://0011-v4l2-Set-VB2_MAX_FRAME-VIDEO_MAX_FRAME-to-128.patch \
    file://0012-epc660-Add-device-driver-support.patch \
    file://0013-imx8mp-evk.dts-Add-epc660-and-tc358746-nodes-to-dts.patch \
    file://0014-Add-imx8mp-irma6r2-devicetree.patch \
    file://0015-imx8mp-irma6r2.dts-configuration-for-irma6r2.patch \
    file://0016-rtc-pcf8563-Skip-registering-of-clkout-for-RTC.patch \
    file://0017-i2c-imx-remove-unneeded-sleep.patch \
    file://0018-i2c-imx-Introduce-optional-busy-polling-for-xfer.patch \
    file://0019-lm75.c-Defer-probe-if-i2c-communication-fails-with-E.patch \
    file://0020-media-tc358746-fix-the-pll-calculating-function.patch \
    file://0021-tc358746.c-Move-vb-size-calculation-to-seperate-func.patch \
    file://0022-tc358746.c-Add-RAW12-and-RAW14.patch \
    file://0023-tc358746.c-Add-empty-s_power-and-link_setup-function.patch \
    file://0024-tc358746.c-Implement-hsync-vsync-polarity-config.patch \
    file://0025-tc358746.c-Hack-Do-not-call-remote-epc660-s_stream.patch \
    file://0026-imx93-matrixup.dts-Copy-device-tree-from-imx93-11x11.patch \
    file://0027-imx93-matrixup.dts-Remove-FEC-node.patch \
    file://0028-imx93-matrixup.dts-Remove-flexcan2.patch \
    file://0029-imx93-matrixup.dts-Remove-lcdif-adv7535-dsi.patch \
    file://0030-imx93-matrixup.dts-Remove-unused-nodes.patch \
    file://0031-imx93-matrixup.dts-Adapt-pmic-eqos-phy-nodes-and-rem.patch \
    file://0032-imx93-matrixup.dts-Remove-ptn5110-usbotg-nodes.patch \
    file://0033-imx93-matrixup.dts-Configure-pinctrl-for-GPIO3-s.patch \
    file://0034-imx93-matrixup.dts-Add-fpga-and-related-nodes.patch \
    file://0035-usb-usbmisc_imx-Workaround-for-i.MX93-ERR051725.patch \
    file://0036-Backport-dp83822.c.patch \
    file://0037-net-phy-dp83822-Configure-RMII-mode-on-DP83825-devic.patch \
    file://0039-fpga-Add-Efinix-Trion-Titanium-serial-SPI-programmin.patch \
    file://0040-trion-mipi-Add-fpga-bridge-driver.patch \
    file://0041-imx8mp-irma6r2.dts-tc358746-csi-dphy-450Mhz.patch \
    file://0042-imx8mp-irma6r2-Add-dts-overlay-for-board-revision-3.patch \
    file://0043-imx8-isi-cap.c-improve-output-in-case-of-discarded-b.patch \
    file://0044-powerfail-manager-Add-driver.patch \
    file://0045-nvmem-imx-ocotp-fsb-s400-Add-property-fsb_disable_sh.patch \
    file://0046-firmware-imx-ele-Fix-fuse-write-for-payload-0x0.patch \
    file://0047-ele-Avoid-special-threatment-for-fuse_id-1.patch \
    file://0048-trion-mipi.c-Add-custom-ioctl-to-load-fpga-firmware.patch \
    file://0049-marec-fpga.c-Add-custom-ioctl-to-load-fpga-firmware.patch \
    file://0050-fpga-xilinx-spi-Lock-spi-device-for-exclusive-access.patch \
    file://0051-hwmon-ad7314-Force-spi-controller-to-operate-with-16.patch \
"

# It has no effect to set KERNEL_DEVICETREE in the conf/multiconfig/imx93-evk.conf,
# because it is overwritten from the meta-freescale/conf/machine/imx93-11x11-lpddr4x-evk.conf.
KERNEL_DEVICETREE:imx93-11x11-lpddr4x-evk = " freescale/${KERNEL_DEVICETREE_BASENAME}-marec-fpga.dtb"

SRC_URI:append:poky-iris-deploy = "\
    file://deploy.cfg \
"

# Don't include kernels in standard images
RRECOMMENDS:${KERNEL_PACKAGE_NAME}-base = ""
