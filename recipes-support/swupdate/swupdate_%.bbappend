# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

wwwdir = "/var/www/swupdate"

# Put reset script right after counting application
RESET_SCRIPT="reset_upgrade_available.sh"
RESET_SCRIPT_SYM="S92reset_upgrade_available"

SRC_URI_append := " \
	file://defconfig \
	file://${RESET_SCRIPT} \
	file://swupdate_default_args \
	file://bootloader_update.lua \
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

	# all machines are v1.0 for now
	install -d $(basename -- ${D}${SWUPDATE_HW_COMPATIBILITY_FILE})
	echo "${MACHINE} 1.0" > ${D}${SWUPDATE_HW_COMPATIBILITY_FILE}
}
