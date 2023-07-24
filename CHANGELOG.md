# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [APR's Version Numbering](https://apr.apache.org/versioning.html)

## version/2.0.18-dev (HEAD) - n/a
### Added
- [APC-6721]: Switch log file location
- [APC-6709]: Add a virtual gpiochip to the power manager module

### Changed


### Deprecated


### Removed


### Fixed
- [APC-6658]: Restrict permissions to key files

### Simulation only


### Maintenance only


### Known issues




## version/2.0.17 - 2023-07-19
### Added
- [APC-6781]: Updated EPC660 sequencer file to v14 (R1 & R2)

### Changed
- [APC-6765]: Checking for already running ntp processed (R1) and reload sources with chronyc (R2)

### Fixed
- [APC-6769]: selftest: Always set the ubootenv firmware after a successful boot


## version/2.0.16 - 2023-06-23
### Added
- [APC-6160]: chrony: Add NTS certificate to chrony.conf
- [APC-5918]: Add jsoncpp patch to fix SDK build
- [APC-6277]: Allow update via swupdate only if installed firmware has version 2.1.5 or higher
- [APC-6101]: Add persistent logging support for initramfs's emergency switch
- [APC-5533]: Add recipe for tdewolff's minify tool for web formats
- [APC-6322]: Add epc660 and serializer reset patches for 2kV surge test
- [APC-6158]: Added the option to use a custom DHCP option 61 client identifier.
- [APC-6296]: power_on_selftest.sh: Add shared lockfile
- [APC-6513]: Added the ability get ntp server list from DHCP server via option 42 and starting the daemon
- [APC-6679]: Add irma\_identity group
- [APC-6689]: Add powerfail manager kernel module

### Changed
- [APC-5918]: Update this layer to kirkstone, including refactoring of various recipes
- [APC-5922]: linux-fslc-imx updated to 5.15
- [APC-5928]: u-boot-imx updated to 2022.04
- [APC-5925]: Minor tweaks to reduce firmware size of R1
- [APC-6296]: Add rsyslog tls configuration
- [APC-6357]: Support for non-root user execution, fix scripts and add users/groups (R2 only)
- [APC-5571]: Clean up recipes and image installs, move scripts from meta-iris to this layer

### Fixed
- Fix: Use default timestamp file on first boot
- [APC-6279]: Run lvresize when updating alternative firmware in power on selftest
- [APC-6119]: Fix defconfig handling in linux-fslc-imx kernel recipe
- [APC-6374]: Enable device correct shutdown
- [APC-6679]: Fix permissions of identity keys


## version/2.0.15 - 2023-04-12
### Fixed
- Possible error during factory reset fixed


## version/2.0.14 - 2023-04-05
### Fixed
- imx repos moved from codeaurora to github


## version/2.0.13 - 2023-03-23
### Fixed
- [APC-6103]: rsyslog: include rw config with mode option
- [APC-5926]: Remove deprecated unit addresses from fitimage signing


## version/2.0.12 - 2023-03-03
### Added
- [APC-5579]: factory-reset.sh: Add force option
- [APC-5725]: Share factory reset script between R1 and R2
- [DEVOPS-590]: Add FindAvahi.cmake to avahi and Findswupdate.cmake to swupdate to allow usage in cmake projects
- [APC-5893]: respect EPC660 specified reset timings
- [APC-5574]: remove customer folder on factory reset
- [APC-5792]: Release 2: Default to https in flashall.uuu, swuimage and factory reset script
- [APC-5942]: Add openssl-bin and download.crt
- [APC-5994]: swupdate: Check if sensor has identity crt/key before updating
- [APC-5993]: Add emergency fw A/B switch in case of fs corruption

### Removed
- [APC-5542]: Remove netboot image
- [DEVOPS-590]: Remove unconditional installing of sqlite3 and nginx

### Fixed
- [APC-5954]: Fix RTC clkout disable when clock register is skipped


## version/2.0.11 - 2022-11-29
### Added
- Allow end/pos1/del commands in UART terminal
- [RDPHOEN-1402]: Add snake oil identity cert/key with root CA
- [RDPHOEN-1402]: uuu: Create rw location for nginx sites-enabled
- [RDPHOEN-1404]: Create symlink for webtls and default webserver conf symlink
- [RDPHOEN-1327]: Save timestamp on rw partition (only R2)
- [RDPHOEN-1327]: Add script that periodically saves the timestamp
- [APC-5379]: Add fitImage SRK verification on update
- [APC-5286]: Keep current and alternative firmware to be the same after a successfull update
- [APC-5286]: Update alternative bootloader after successfull update
- [APC-5376]: Add power on selftest after update
- [APC-4580]: Add predefined avahi service to publish a http service
- [APC-5470]: Add factory reset

### Changed
- Enable Debug-Tweaks (UART root access) on all R1 images


## version/2.0.10 - 2022-10-13
### Added
- [RDPHOEN-1364]: Add nftables firewall userspace application
- [RDPHOEN-1364]: Add ip addr syntax validation when setting static ip

### Changed
- [RDPHOEN-1314]: Revert &quot;Use only one MIPI lane on R2&quot;
- [RDPHOEN-1357]: Adjust hs-settle MIPI configuration

### Fixed
- [RDPHOEN-1314]: Fix tc358746 serializer configuration
- [RDPHOEN-1371]: swupdate: Bind swupdate to localhost

### Removed
- [RDPHOEN-1326]: Remove kernel-modules


## version/2.0.9 - 2022-09-09
### Changed
- [RDPHOEN-1314]: Revert &quot;Disable PWM clock for serializer on R2&quot;
- [RDPHOEN-1314]: Use only one MIPI lane on R2 (with PWM and minor corrections)


## version/2.0.8 - 2022-09-07
### Added
- [RDPHOEN-1281]: Copy snake oil identity key/cert with uuu for dev usage
- [RDPHOEN-1348]: Enforce major updates


## version/2.0.7 - 2022-08-26
### Fixed
- swupdate: pre_post_inst.sh: Don't rely on the default iv and use the new one passed by the sw-description


## version/2.0.6 - 2022-08-30
### Changed
- [RDPHOEN-1314]: Disable PWM clock for serializer on R2

### Fixed
- [RDPHOEN-1299]: Fix r/w access on netfitboot
- [RDPHOEN-1299]: Fix init script terminal output
- [RDPHOEN-1289]: set persistent path for dropbear rsa host key (IRMA 6 Release 2)


## version/2.0.5 - 2022-08-26
### Changed
- Do not deploy production swupdate key to rootfs


## version/2.0.4 - 2022-08-24
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
- [RDPHOEN-1040]: Add &quot;sync&quot; command in uuu flash script
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

### Removed
- [RDPHOEN-958]: Removing the bootloader code configuration CONFIG_CMD_BOOTEFI for imx8mpevk and imx8mp-irma6r2, as (u)efi isn't used
- [RDPHOEN-1179]: Remove mfgtool unneeded dependency to speed up build time
- imx8mp multiconfig: Remove impractical wic images, because they can not be used with current SOC encrypted volumes
- [DEVOPS-549]: Remove Jenkinsfile, using gitlab ci instead

### Fixed
- [RDPHOEN-1013]: Fix setting the format on the Serializer, enables switching between Raw12 and Raw14 formats without setting the format twice
- [RDPHOEN-1150]: Fix fsl-dsp devicetree node in linux-fslc, place reserved memory region inside RAM bounds


## version/2.0.3 - 2022-03-23
### Added
- Add swupdate image creation recipe


## version/2.0.2 - 2022-01-25
### Removed
- [APC-3693][APC-3971] libmosquitto and libmosquittopp removed


## version/2.0.1 - 2021-06-10
### Added
- add multiconfigs for QEMU images

### Changed
- prepare layer for upcoming CI

### Fixed
- gcc: Backport bugfix for bug 101510: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=101510


## version/2.0.0 - 2021-07-16
### Changed
- bump linux kernel version to 4.14.233. updating the linux kernel. in the process backported patches do no longer apply.

### Fixed
- Re-add python3 support in perf tools
- [RDSBUG-568] Streamline firmware versioning
- Move DISTRO_VERSION declaration to KAS repository

### Removed
- Remove static ip, which is configured by the eth0-pre-up script if needed.


## version/1.0.0 - 2021-05-28
### Added
- This is the initial release of meta-iris-base, a yocto meta-layer which contains all recipes in order to build the Iris base Linux image


