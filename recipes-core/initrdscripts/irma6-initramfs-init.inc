# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

SUMMARY = "initramfs image init script for irma6"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
    file://init_bootstrap.sh \
    file://init_mountmmc.sh \
    file://init_mountnfs.sh \
    file://init_warnnetboot.sh \
    file://init_switchroot.sh \
"

RDEPENDS_${PN} = " \
    busybox \
    util-linux-mount \
    util-linux-findfs \
    util-linux-uuidd \
    cryptsetup \
    keyutils \
    lvm2 \
"

S = "${WORKDIR}"

SCRIPTORDER ?= "bootstrap mountmmc switchroot"

do_install_prepend() {
    cd ${WORKDIR}
    echo -n > initramfs-init.sh
    for snippet in ${SCRIPTORDER}
    do
        cat init_${snippet}.sh >> initramfs-init.sh
    done
}

do_install() {
	install -d ${D}${base_sbindir}
	install -m 0755 ${WORKDIR}/initramfs-init.sh ${D}${base_sbindir}/init

	install -d ${D}/dev
	mknod -m 622 ${D}/dev/console c 5 1
}

inherit allarch

FILES_${PN} = "/dev ${base_sbindir}/init"
