# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

DEPENDS += " \
	pkgconfig \
	nettle \
	gnutls \
"

do_configure_prepend() {
    export PKG_CONFIG="/usr/bin/pkg-config"
    export PKG_CONFIG_PATH="${WORKDIR}/recipe-sysroot/usr/lib/pkgconfig/"
    export alias shell='/bin/sh'
}
