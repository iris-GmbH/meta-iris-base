# SPDX-License-Identifier: MIT
# Copyright (C) 2026 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-ethosu-keep-only-offline-Vela-execution-path.patch \
    file://0002-ethosu-remove-embedded-Python-ModelConverter.patch \
    file://0003-Do-not-link-against-libpython3-drop-target-Python-discovery-and-defines.patch \
"
