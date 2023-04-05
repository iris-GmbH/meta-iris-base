# Copyright (C) 2023 iris-GmbH infrared & intelligent sensors

SUMMARY = "IRMA 6 R2 cgroup setup"
DESCRIPTION = "IRMA 6 R2 cgroup setup"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    file://cgroup-setup-base \
    file://cgroup-setup-functions \
"

FILES:${PN} += " \
	${sysconfdir}/init.d/cgroup-setup \
	${datadir}/cgroup-setup-functions \
"

INITSCRIPT_NAME = "cgroup-setup"
INITSCRIPT_PARAMS = "defaults 80"

inherit update-rc.d

# Allow external network access and allow subprocesses
ALLOW_EXTERNAL_NETWORK = " \
    /usr/sbin/dropbearmulti \
"

ALLOW_EXTERNAL_NETWORK_STRICT = " \
    /usr/sbin/nginx \
    /usr/sbin/rsyslogd \
    /usr/sbin/chronyd \
    /usr/sbin/avahi-daemon \
    /sbin/udhcpc \
"

ALLOW_INTERNAL_NETWORK_STRICT = " \
    /usr/bin/swupdate \
"

# The cgroup-setup init script will check if the above binaries exist and will put all PIDs related to each binary in the cgroup
# This is a one-shot execution, if any process is restarted it is no longer part of a cgroup
# The irma6 applications will be placed into the cgroups by their init scripts (see meta-iris layer)

do_compile() {
    cp ${WORKDIR}/cgroup-setup-base ${B}/cgroup-setup

    for i in ${ALLOW_EXTERNAL_NETWORK}
    do
        echo "init_cgroup \"$i\" \"\$CLASSID_EXTERNAL\"" >> ${B}/cgroup-setup
    done

    for i in ${ALLOW_EXTERNAL_NETWORK_STRICT}
    do
        echo "init_cgroup \"$i\" \"\$CLASSID_EXTERNAL\" 0" >> ${B}/cgroup-setup
    done

    for i in ${ALLOW_INTERNAL_NETWORK_STRICT}
    do
        echo "init_cgroup \"$i\" \"\$CLASSID_INTERNAL\" 0" >> ${B}/cgroup-setup
    done
}

do_install() {
    # System V init script
    install -d ${D}${sysconfdir}/init.d
    install -m 755 ${B}/cgroup-setup ${D}${sysconfdir}/init.d
    
    install -D -m 0755 ${WORKDIR}/cgroup-setup-functions ${D}${datadir}/cgroup-setup-functions
}
