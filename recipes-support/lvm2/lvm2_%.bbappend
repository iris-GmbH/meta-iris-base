# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

do_compile:append:poky-iris-0501 () {
    if ! grep -q 69-dm-lvm.rules "${S}/udev/Makefile.in"; then
        bbfatal "69-dm-lvm.rules can not be found in Makefile.in"
    fi

    # Remove 69-dm-lvm.rules from the final Makefile, because it requires systemd, see https://github.com/lvmteam/lvm2/blob/v2_03_16/udev/69-dm-lvm.rules.in#L83
    sed -i "s|69-dm-lvm.rules||g" "${S}/udev/Makefile"
}
