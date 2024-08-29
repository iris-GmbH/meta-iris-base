# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

# remove unnecessary target dependencies
PACKAGECONFIG:remove:class-target = "python"

# removing python from PACKAGECONFIG:class-target will break libxml2-native
# Therefore we force-include python3 class
inherit python3targetconfig

# overwrite default config for minimal build size with necessary features
EXTRA_OECONF:class-target = "--with-minimum --with-tree --with-schemas --with-sax1 --with-output"

CFLAGS:append:poky-iris-0601 = " -Os"