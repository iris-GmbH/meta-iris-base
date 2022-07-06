# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

wwwdir = "/var/www/swupdate"

# Put reset script right after counting application
RESET_SCRIPT="reset_upgrade_available.sh"
RESET_SCRIPT_SYM="S92reset_upgrade_available"

# use git instead of quilt to apply binary patch as well
PATCHTOOL = "git"

SRC_URI_append := " \
	file://defconfig \
	file://${RESET_SCRIPT} \
	file://swupdate_default_args \
	file://bootloader_update.lua \
	file://0001-RDPHOEN-1221-Formatting-index.html.patch \
	file://0002-RDPHOEN-1221-SWUpdate-Webinterface-CI-rework.patch \
"

RDEPENDS_${PN} += " \
	util-linux-sfdisk \
	jq \
	libubootenv-bin \
	swupdate-lualoader \
"

FILES_${PN} += " \
	${SWUPDATE_HW_COMPATIBILITY_FILE} \
	${sysconfdir}/init.d/${RESET_SCRIPT} \
	${sysconfdir}/rc5.d/${RESET_SCRIPT_SYM} \
	${sysconfdir}/swupdate/conf.d/swupdate_default_args \
"

SWU_HW_VERSION ?= "${@'0.0' if not d.getVar('HW_VERSION') else d.getVar('HW_VERSION')}"

do_install_append () {
	install -d ${D}${sysconfdir}/init.d
	install -d ${D}${sysconfdir}/rc5.d
	install -m 0755 ${WORKDIR}/${RESET_SCRIPT} ${D}${sysconfdir}/init.d
	ln -s -r ${D}${sysconfdir}/init.d/${RESET_SCRIPT} ${D}${sysconfdir}/rc5.d/${RESET_SCRIPT_SYM}

	# set swupdate default arguments
	install -d ${D}${sysconfdir}/swupdate/conf.d/
	install -m 0644 ${WORKDIR}/swupdate_default_args ${D}${sysconfdir}/swupdate/conf.d/

	# install lua handlers
	install -d ${D}${libdir}/swupdate/lua-handlers
	install -m 0644 ${WORKDIR}/bootloader_update.lua ${D}${libdir}/swupdate/lua-handlers/

	# set /etc/hwrevision
	if [ "${SWU_HW_VERSION}" = "0.0" ]; then
		bbwarn "SWU_HW_VERSION is not set in the machine conf file. Use ${SWU_HW_VERSION} for now!"
	fi
	install -d $(basename -- ${D}${SWUPDATE_HW_COMPATIBILITY_FILE})
	echo "${MACHINE} ${SWU_HW_VERSION}" > ${D}${SWUPDATE_HW_COMPATIBILITY_FILE}
}
