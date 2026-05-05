# SPDX-License-Identifier: MIT
# Copyright (C) 2026 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-adi:"

SRC_URI:append = " \
    file://defconfig \
    file://0001-kbuild-fix-shared-modfile-quoting-for-single-builds.patch \
    file://0002-dma-buf-heaps-add-IRMA-DSP-carveout-heap.patch \
    file://0003-misc-iris-add-DSP-DMA-BUF-address-helper.patch \
    file://0004-misc-iris-add-cache-flush-compatibility-driver.patch \
    file://0005-misc-iris-add-SHARC-core-control-driver.patch \
    file://0006-misc-iris-add-SHARC-mailbox-driver.patch \
    file://0007-misc-add-Iris-compatibility-driver-menu.patch \
    file://0008-dma-adi-expose-helpers-for-media-capture.patch \
    file://0009-media-adi-add-PPI-helper.patch \
    file://0010-media-adi-add-SC5xx-video-capture-driver.patch \
    file://0011-media-i2c-add-EPC660-sensor-driver.patch \
    file://0012-media-dt-bindings-add-ADI-PPI-control-bits.patch \
    file://0013-media-platform-add-ADI-capture-menu.patch \
    file://0014-ARM-dts-add-SC573-Gen6-base-board.patch \
    file://0015-ARM-dts-sc573-gen6-add-IRMA-DSP-heap.patch \
    file://0016-ARM-dts-sc573-gen6-add-IRMA-DSP-address-helper.patch \
    file://0017-ARM-dts-sc573-gen6-add-cache-flush-node.patch \
    file://0018-ARM-dts-sc573-gen6-add-SHARC-core-control.patch \
    file://0019-ARM-dts-sc573-gen6-add-SHARC-mailboxes.patch \
    file://0020-ARM-dts-sc573-gen6-add-EPC660-capture-path.patch \
    file://0021-ARM-dts-sc573-gen6-enable-DMA-for-SPI-flash.patch \
    file://0022-ARM-dts-sc573-gen6-enable-I2C2.patch \
    file://0023-mtd-spi-nor-mask-4-4-4-on-adi-spi3-and-log-read-sele.patch \
    file://0024-mtd-spi-nor-Fix-MEMUNLOCK-for-IS25LP256.patch \
    file://0025-misc-adi-add-SC57x-TMU-character-device.patch \
    file://0026-misc-adi-add-SC57x-hwrev-character-device.patch \
    file://0027-ARM-dts-Fix-SD-Card-Support.patch \
    file://0028-spi-adi-spi3-Fix-DMA-cleanup-from-error-IRQ.patch \
    file://0029-ARM-configs-add-SC573-Gen6-base-defconfig.patch \
"

SRC_URI:remove = " \
    file://feature/cfg/nfs.cfg \
    file://feature/cfg/wireless.cfg \
    file://feature/cfg/cpufreq.cfg \
    file://feature/cfg/crypto.cfg \
    file://feature/cfg/tracepoints.cfg \
"
