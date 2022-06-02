# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [APR's Version Numbering](https://apr.apache.org/versioning.html).

## [2.0.4] -dev (HEAD) - n/a
### Added
- [RDPHOEN-957]: Add script for IP configuration (eth:0.0 .. DHCP or static customer IP retrieved from customer configuration; eth:0.1 service IP 172.16.x.y calculated from MAC address)
- [RDPHOEN-1034/1035/1036]: Add support for irma6-r2 machine, including patches for bootloader, boot image creation and kernel
- [RDPHOEN-1067] Added R2 support in cloud Jenkins 
- [DEVOPS-491] CST tool mirror and correct licensing
- [APC-4501] Added backport of chrony recipe for NTS support introduced with v4.0
- [APC-4244]: Add nginx and sqlite3 as required by the new password protection of the webinterface
- [RDPHOEN-1083]: Add HAB support on imx8, enable and switch to fit image boot
- [RDPHOEN-1083]: Sign bootable image: imx-boot.signed
- [RDPHOEN-1142]: Add signing and fitimage configuration and recipes for irma6 fitimages
- [RDPHOEN-1129]: LVM setup with R2 uuu images, switch to booting signed fitimages with initramfs
- [RDPHOEN-1079]: Bump BL31 to v2.4, enables booting newer kernels
- [RDPHOEN-1143]: Add dm-verity for rootfs volumes (in uuu and initramfs)
- [RDPHOEN-1164]: initramfs-init: Dynamically select the correct rootfs from the kernel cmd line argument
- linux-fslc-iris: Remove kernel from the rootfs & initramfs, because it remains unused for the fitImage setup
- [RDPHOEN-1140]: Add redundand u-boot-env support and missing release 2 packages: lvm2, cryptsetup libubootenv-bin
- [RDPHOEN-1178]: Add CAAM rng prediction resistance in Uboot, enables the correct hw rng initialization in Linux.
- [RDPHOEN-1180]: Use different fstab for R2 to mount the userdata volume


### Changed


### Deprecated


### Removed
- [RDPHOEN-958]: Removing the bootloader code configuration CONFIG_CMD_BOOTEFI for imx8mpevk and imx8mp-irma6r2, as (u)efi isn't used
- [RDPHOEN-1179]: Remove mfgtool unneeded dependency to speed up build time

### Fixed
- [RDPHOEN-1013]: Fix setting the format on the Serializer, enables switching between Raw12 and Raw14 formats without setting the format twice
- [RDPHOEN-1150]: Fix fsl-dsp devicetree node in linux-fslc, place reserved memory region inside RAM bounds


### Simulation only


### Maintenance only


### Known issues



## [2.0.3] - 2022-03-23
### Added
- Add swupdate image creation recipe



## [2.0.2] - 2022-01-25
### Removed
- [APC-3693][APC-3971] libmosquitto and libmosquittopp removed



## [2.0.1] - 2021-06-10
### Added
- add multiconfigs for QEMU images


### Changed
- prepare layer for upcoming CI


### Fixed
- gcc: Backport bugfix for bug 101510: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=101510



## [2.0.0] - 2021-07-16
### Changed 
- bump linux kernel version to 4.14.233. updating the linux kernel. in the process backported patches do no longer apply.

### Fixed
- Re-add python3 support in perf tools
- [RDSBUG-568] Streamline firmware versioning
- Move DISTRO_VERSION declaration to KAS repository

### Removed
- Remove static ip, which is configured by the eth0-pre-up script if needed.


## [1.0.0] - 2021-05-28
### Added
- This is the initial release of meta-iris-base, a yocto meta-layer which contains all recipes in order to build the Iris base Linux image
