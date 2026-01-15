# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

wwwdir = "/var/www/swupdate"

# use git instead of quilt to apply binary patch as well
PATCHTOOL = "git"

SRC_URI:append := " \
	file://defconfig \
	file://swupdate.sh \
	file://swupdate.cfg.in \
	file://bootloader_update.lua \
	file://Findswupdate.cmake \
	file://0001-Apply-iris-Coporate-Design-to-webinterface.patch \
	file://0002-mongoose_multipart-Allow-raw-binary-uploads.patch \
"

SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'file://swupdate-systemd.cfg', '', d)}"

DEPENDS += " \
	bc-native \
"

RDEPENDS:${PN} += " \
	util-linux-sfdisk \
	jq \
	libubootenv-bin \
	swupdate-lualoader \
	openssl-bin \
	nginx \
	lvm2 \
	mmc-utils \
	e2fsprogs-resize2fs \
	e2fsprogs-e2fsck \
	util-linux-blockdev \
	keyutils \
	cryptsetup \
	power-on-selftest \
"

# Include more RDEPENDS for pre_post_inst.sh in swuimage, but only for real hardware
RDEPENDS:${PN}:append:mx8mp-nxp-bsp = " \
	hab-csf-parser \
	hab-srktool-scripts \
	keyctl-caam \
"

RDEPENDS:${PN}:append:poky-iris-0501 = " \
	irma-helper-scripts \
"

FILES:${PN} += " \
	${SWUPDATE_HW_COMPATIBILITY_FILE} \
	${sysconfdir}/swupdate.cfg \
"

SWU_HW_VERSION ?= "${@'0.0' if not d.getVar('HW_VERSION') else d.getVar('HW_VERSION')}"

do_install:append () {
	# create swupdate.cfg and replace variables
	cp ${WORKDIR}/swupdate.cfg.in ${WORKDIR}/swupdate.cfg
	export FW_VERSION=`echo ${DISTRO_VERSION} | grep -oP '\d+\.\d+'`
	if [ -z "$FW_VERSION" ]; then
		bbfatal "ERROR: Can not read firmware version"
	fi
	sed -i "s|FW_VERSION|$FW_VERSION|g" ${WORKDIR}/swupdate.cfg

	# enforce max-version to MAJOR+1.999
	MAJOR=$(echo $FW_VERSION | cut -d"." -f1)
	export MAX_VERSION="$(echo "$MAJOR+1" | bc).999"
	sed -i "s|MAX_VERSION|$MAX_VERSION|g" ${WORKDIR}/swupdate.cfg

	# copy swupdate.cfg
	install -d ${D}${sysconfdir}
	install -m 644 ${WORKDIR}/swupdate.cfg ${D}${sysconfdir}

	# install lua handlers
	install -d ${D}${libdir}/swupdate/lua-handlers
	install -m 0644 ${WORKDIR}/bootloader_update.lua ${D}${libdir}/swupdate/lua-handlers/

	# set /etc/hwrevision
	if [ "${SWU_HW_VERSION}" = "0.0" ]; then
		bbwarn "SWU_HW_VERSION is not set in the machine conf file. Use ${SWU_HW_VERSION} for now!"
	fi
	install -d $(basename -- ${D}${SWUPDATE_HW_COMPATIBILITY_FILE})
	echo "${MACHINE} ${SWU_HW_VERSION}" > ${D}${SWUPDATE_HW_COMPATIBILITY_FILE}

	install -d ${D}${datadir}/cmake/Modules
	install -m 644 ${WORKDIR}/Findswupdate.cmake ${D}${datadir}/cmake/Modules
}
