# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://imx8mp-evk-r2_defconfig \
    file://0001-Add-RAW12-to-supported-formats-in-imx-mipi-csi-drive.patch \
    file://0002-Add-subdev-notification-to-mxc_mipi_csi.patch \
    file://0003-Fix-Save-csis-format-to-internal-structure-of-imx8-m.patch \
    file://0004-Add-ADDI90xx-camera-to-imx8-media-platform.patch \
    file://0005-Change-devicetree-of-imx8mp-evk-to-include-addi90xx-.patch \
    file://0006-Enable-16-bit-swapping-in-mx6s-capture-driver.patch \
    file://0007-Add-custom-dequeue-function-to-imx8-isi-cap-driver.patch \
    file://0008-WIP-Add-epc660-support.patch \
    file://0009-WIP.patch \
    file://0010-WIP.patch \
    file://0011-tc358746-add-async_notifier-support.patch \
    file://0012-imx8-media-dev-fix-source-sink-pad-setup.patch \
    file://0013-imx8mp-evk-DT-adjustments.patch \
    file://0014-epc660-register-enable-pads-and-entity.patch \
    file://0015-epc660-fix-custom-reset-IOCTL.patch \
    file://0016-epc660-setup-sensible-hblank-value.patch \
    file://0017-tc358746-return-ENOTCONN-if-there-is-no-link.patch \
    file://0018-tc358746-return-error-if-width-is-zero.patch \
    file://0019-tc358746-add-Raw12-format-support.patch \
    file://0020-imx8-mipi-csi2-sam-add-Y12_1X12.patch \
    file://0021-mipi-csi2-sam-fix-MEDIA-MIX-gasket0-dumps.patch \
    file://0022-tc358746-rx-endpoint-in-state-check-properties.patch \
    file://0023-tc358746-handle-hsync-vsync-during-fwnode-parsing.patch \
    file://0024-Enable-640x120-format-for-Pipeline.patch \
    file://0025-Set-tc358746-buffers-when-setting-format.patch \
"

KERNEL_DEFCONFIG_imx8mpevk = "imx8mp-evk-r2_defconfig"
