# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [APR's Version Numbering](https://apr.apache.org/versioning.html).

## [2.0.6-dev] (HEAD) - n/a
### Added


### Changed


### Deprecated


### Removed


### Fixed
- [RDPHOEN-1289]: set persistent path for dropbear rsa host key (IRMA 6 Release 2)
- swupdate: pre_post_inst.sh: Don't rely on the default iv and use the new one passed by the sw-description

### Simulation only


### Maintenance only


### Known issues



## [2.0.5] - 2022-08-26
### Changed
- Do not deploy production swupdate key to rootfs



## [2.0.4] - 2022-08-24
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
- [RDPHOEN-1153]: Add u-boot env writeable list feature
- [RDPHOEN-1180]: Use different fstab for R2 to mount the userdata volume
- [RDPHOEN-1140]: Make swu images work with new partitioning/volumes
- [RDPHOEN-1144]: Bump Kernel to 5.4-2.3.x-imx and enable CAAM API
- [RDPHOEN-1142]: Enable encrypted storage and CAAM auto-unlock mechanism
- [RDPHOEN-1194]: swupdate: Add postupdate cmd: reboot
- [RDPHOEN-1154] Implementing bootcount_limit for imx8mp-evk and imx8mp-irma6r2
- [RDPHOEN-1165]: Add netboot fitimage for R2
- [RDPHOEN-256]: Add linux watchdog feature
- [RDPHOEN-1192]: Add encrypted storage swupdate support
- [RDPHOEN-1182]: Configure swupdate's fallback webserver mongoose and add swupdate's www root
- [RDPHOEN-1182]: Move nginx content to meta-iris to avoid multiple nginx_%.bbappend's
- [RDPHOEN-1182]: Enable read-only-rootfs tweaks and use default's fstab mount points
- [RDPHOEN-1060] Add kernel driver for eth0 ADIn1200 PHY
- [RDPHOEN-1060]: Fix eqos driver in uboot to get ethernet working on release 2 hardware
- [RDPHOEN-255]: Add Bootloader Update procedure for eMMC with SWUpdate
- [RDPHOEN-1221]: Applying Iris Coporate Design to SWUpdate webinterface
- [RDPHOEN-1226]: Adjust EPC660 & Serializer reset pins
- [RDPHOEN-618]: Unify swupdate hwrevision check
- [RDPHOEN-618]: Enable FW Version check for swuimages
- [DEVOPS-522]: Add dev keys for swupdate signing, move existing keys from iris-kas repo to meta-iris-base
- [RDPHOEN-1120]: swupdate: Enable support for signed images
- [RDPHOEN-1120]: swupdate: Enable support for encrypted images
- [RDPHOEN-1220]: Add IU EEPROM readout for nfs boot flag
- [RDPHOEN-1225]: Add IU EEPROM readout for mac address
- [RDPHOEN-1120]: swupdate: Enable support for rotating iv for encrypted swu images
- [RDPHOEN-1250]: swupdate: Add check if swupdate still runs after update
- [RDPHOEN-1204]: Add dosfstools to imx8mp irma6-base for formatting with FAT (mkfs.vfat)
- [RDPHOEN-1204]: Add e2fsprogs-mke2fs to imx8mp irma6-base for formatting with ext4 (mkfs.ext4)
- [RDPHOEN-1213]: swupdate: Use swupdate.cfg instead of args and add more handler for future use
- [RDPHOEN-1163]: Pregenerate and sign dmverity hashes
- [RDPHOEN-1257]: Add resizing of rootfs logical volume during update
- [APC-4848]: Add rsyslog integration for IRMA 6 R2.
- [APC-4836]: Add chrony integration for IRMA 6 R2.
- [APC-4836] Disable internal snvs rtc on r2.
- [RDPHOEN-1040]: Add "sync" command in uuu flash script
- [RDPHOEN-1084]: Add config fragment for kernel and u-boot
- [RDPHOEN-1273]: Add encryption of logical volumes to initramfs to use valid black key blobs
- [RDPHOEN-1270]: Add check for when the device is locked to not nfs boot
- [RDPHOEN-1228]: Add SRK bootloader check for secure boot activated devices
- [APC-4910] Added rsyslog template according to RFC5424

### Changed
- [DEVOPS-519] Moved config from iris-kas local.conf to meta-iris-base distro.conf
- [RDPHOEN-1203]: Change to new mmc-utils repo url for the mmc erase command
- [DEVOPS-531] Split distro configs into deploy and maintenance
- [RDPHOEN-1257]: Changed to only enable debug-tweaks for maintenance build
- [RDPHOEN-1152]: Disable u-boot console and boot delay for deploy build
- [RDPHOEN-1295]: Increase critical CPU temperature for R2 to 105 degree celsius
- [RDPHOEN-1314]: Disable PWM clock for serializer on R2


### Removed
- [RDPHOEN-958]: Removing the bootloader code configuration CONFIG_CMD_BOOTEFI for imx8mpevk and imx8mp-irma6r2, as (u)efi isn't used
- [RDPHOEN-1179]: Remove mfgtool unneeded dependency to speed up build time
- imx8mp multiconfig: Remove impractical wic images, because they can not be used with current SOC encrypted volumes
- [DEVOPS-549]: Remove Jenkinsfile, using gitlab ci instead

### Fixed
- [RDPHOEN-1013]: Fix setting the format on the Serializer, enables switching between Raw12 and Raw14 formats without setting the format twice
- [RDPHOEN-1150]: Fix fsl-dsp devicetree node in linux-fslc, place reserved memory region inside RAM bounds
- [RDPHOEN-1299]: Fix r/w access on netfitboot
- [RDPHOEN-1299]: Fix init script terminal output


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
