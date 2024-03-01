# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

SUMMARY = "initramfs image init script for irma6"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SCRIPTFILE ?= "initramfs-init.sh"
SRC_URI = "file://${SCRIPTFILE}"

RDEPENDS:${PN} = " \
    busybox \
    util-linux-mount \
    util-linux-findfs \
    util-linux-uuidd \
    cryptsetup \
    keyutils \
    mmc-utils \
    lvm2 \
    openssl-bin \
    iris-signing \
    e2fsprogs-mke2fs \
    nfs-utils \
    libubootenv-bin \
    rsync \
    e2fsprogs-e2fsck \
"

S = "${WORKDIR}"

do_install() {
	install -d ${D}${base_sbindir}
	install -m 0755 ${WORKDIR}/${SCRIPTFILE} ${D}${base_sbindir}/init

	install -d ${D}/dev
	mknod -m 622 ${D}/dev/console c 5 1
}

inherit allarch

FILES:${PN} = "/dev ${base_sbindir}/init"
