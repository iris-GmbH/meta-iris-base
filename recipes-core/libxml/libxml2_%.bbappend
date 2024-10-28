# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

# remove unnecessary target dependencies
PACKAGECONFIG:remove:class-target = "python"

# Removing python from PACKAGECONFIG:class-target will break libxml2-native
# It is a known limitation: https://lists.openembedded.org/g/openembedded-core/topic/108139065
# Therefore we force-include python3 class and remove the python dependency as DEPENDS is evaluated later
inherit python3targetconfig
DEPENDS:remove:class-target = "python3 python3-native"

# overwrite default config for minimal build size with necessary features
EXTRA_OECONF:class-target = "--with-minimum --with-tree --with-schemas --with-sax1 --with-output"

# R2 irma-dev image installs gstreamer-plugins-bad which requires the imx-gpu package which requires wayland
# and wayland does not compile with libxml2 when validation functions are missing, so add them back
EXTRA_OECONF:append:class-target:poky-iris-0602 = " --with-valid"

CFLAGS:append:poky-iris-0601 = " -Os"
