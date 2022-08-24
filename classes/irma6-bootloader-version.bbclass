# The PV in imx-boot is used for the version check in the sw-description file.
# The bootloader version in sw-description is checked against the version
# (read out at runtime) from the signed flash.bin in the /dev/mmcblk2bootX
# partition. A signed storage location in flash.bin is the u-boot and the
# u-boot-spl.

IRIS_IMX_BOOT_RELEASE = "iris-boot_0.1.1"
