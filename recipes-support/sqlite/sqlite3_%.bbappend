# SPDX-License-Identifier: MIT
# Copyright (C) 2024 iris-GmbH infrared & intelligent sensors

# remove features to save space
PACKAGECONFIG:remove = "fts4 fts5 rtree dyn_ext"

CFLAGS:append:poky-iris-0601 = " -Os"
