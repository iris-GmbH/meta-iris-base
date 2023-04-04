# Copyright (C) 2023 iris-GmbH infrared & intelligent sensors

SUMMARY = "IRMA 6 R2 cgroup setup"
DESCRIPTION = "IRMA 6 R2 cgroup setup"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://cgroup-setup-base \
"

INITSCRIPT_NAME = "cgroup-setup"
INITSCRIPT_PARAMS = "defaults 80"

inherit update-rc.d

ALLOW_EXTERNAL_NETWORK = " \
    /usr/sbin/nginx \
    /usr/sbin/dropbearmulti \
"

ALLOW_INTERNAL_NETWORK = " \
    /usr/bin/swupdate \
"

do_compile() {
    cp ${WORKDIR}/cgroup-setup-base ${B}/cgroup-setup

    for i in ${ALLOW_EXTERNAL_NETWORK}
    do
        echo "if [ -x \"$i\" ]; then for p in \$(pidof \"$i\"); do echo \"\$p\" >> /sys/fs/cgroup/external_network/cgroup.procs; done; fi" >> ${B}/cgroup-setup
    done

    for i in ${ALLOW_INTERNAL_NETWORK}
    do
        echo "if [ -x \"$i\" ]; then for p in \$(pidof \"$i\"); do echo \"\$p\" >> /sys/fs/cgroup/internal_network/cgroup.procs; done; fi" >> ${B}/cgroup-setup
    done
}

do_install() {
    # System V init script
    install -d ${D}${sysconfdir}/init.d
    install -m 755 ${B}/cgroup-setup ${D}${sysconfdir}/init.d
}
