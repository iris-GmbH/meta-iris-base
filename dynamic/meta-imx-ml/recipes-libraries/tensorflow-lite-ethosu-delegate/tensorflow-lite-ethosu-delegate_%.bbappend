# SPDX-License-Identifier: MIT
# Copyright (C) 2026 iris-GmbH infrared & intelligent sensors

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-Do-not-link-against-libpython3-as-it-is-not-necessar.patch \
    file://0002-ethosu-keep-only-offline-Vela-execution-path.patch \
    file://0003-ethosu-remove-embedded-Python-ModelConverter.patch \
    file://0004-cmake-drop-target-Python-discovery-and-defines.patch \
"
