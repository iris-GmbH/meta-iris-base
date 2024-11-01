#!/bin/sh

# This script should be executed in a local kernel repository

make mrproper
make imx_v8_defconfig

# disable graphic drivers
scripts/config -d DRM -d IMX_DPU_CORE -d IMX8MP_HDMI_PAVI -d MHDP_HDMIRX -d MHDP_HDMIRX_CEC -d FB -d BACKLIGHT_CLASS_DEVICE -d MALI_MIDGARD

# disable WLAN/CAN/Bluetooth/...
scripts/config -d WLAN -d WIRELESS -d MACVLAN -d BT -d CAN -d NET_9P -d NFC -d USB_NET_DRIVERS -d RC_CORE

# disable system features
scripts/config -d ACPI -d VIRTUALIZATION -d CHROME_PLATFORMS -d HID_SUPPORT -d XEN -d ARCH_KEEMBAY -d SAMPLES

# disable CAAM crypto HW (i.MX93 ELE is enabled elsewhere)
scripts/config -d CRYPTO_HW

# disable unused peripherals
scripts/config -d MTD -d I3C -d PCI -d SCSI -d RAID_ATTRS -d IIO -d ATA -d BLK_DEV_NBD -d VIRTIO_BLK -d INPUT_KEYBOARD -d INPUT_MOUSE -d INPUT_TOUCHSCREEN

# disable audio and unused video
scripts/config -d SOUND -d MEDIA_ANALOG_TV_SUPPORT -d MEDIA_DIGITAL_TV_SUPPORT -d MEDIA_SDR_SUPPORT -d MEDIA_USB_SUPPORT

# disable usb (host mode)
scripts/config -d USB -d USB_MUSB_HDRC -d USB_CDNS_SUPPORT -d USB_DWC3 -d USB_DWC2 -d USB_ISP1760 -d TYPEC

# disable ext2/3 and squashfs
scripts/config -d EXT2_FS -d EXT3_FS -d SQUASHFS -d BTRFS_FS

# disable all ethernet drivers except STMMAC for iMX
sed -i -e '/_NET_VENDOR_/s/=[ym]/=n/g' .config
scripts/config -e NET_VENDOR_STMICRO

# disable all ethernet PHYs except DP83822
sed -i -e '/_G\?PHY=/s/=[ym]/=n/g' .config
scripts/config -e DP83822_PHY

# disable all camera drivers except marec fpga
sed -ne '/^config/s/^config\s\+//gp' drivers/media/i2c/Kconfig | while read -r c; do scripts/config -d "$c"; done
scripts/config -e VIDEO_MAREC_FPGA

# disable all regulators except PMIC PCA9450
sed -i -e '/_REGULATOR_/s/=[ym]/=n/g' .config
scripts/config -e REGULATOR_PCA9450 -e REGULATOR_FIXED_VOLTAGE

# disable all pinctrl except PINCTRL_IMX93
sed -i -e '/_PINCTRL_/s/=[ym]/=n/g' .config
scripts/config -e PINCTRL_IMX93

# disable all imx clks except CLK_IMX93
sed -i -e '/_CLK_IMX/s/=[ym]/=n/g' .config
scripts/config -e CLK_IMX93

# enable features for matrixup
scripts/config -e FW_LOADER_COMPRESS -e FPGA_MGR_XILINX_SPI -d FPGA_BRIDGE -d FW_LOADER_USER_HELPER -e IMX8_MEDIA_DEVICE
scripts/config -e BLK_DEV_DM -e DM_CRYPT -e BLK_DEV_MD -e DM_VERITY -e DM_VERITY_VERIFY_ROOTHASH_SIG
scripts/config -e SENSORS_AD7314 -e EXT4_FS_SECURITY -e TRUSTED_KEYS -e NVMEM_IMX_OCOTP_ELE -e TRUSTED_KEYS_TEE

# fix NEW config options that are visible now
make listnewconfig >> .config

make savedefconfig
cp defconfig arch/arm64/configs/imx93_matrixup_defconfig

