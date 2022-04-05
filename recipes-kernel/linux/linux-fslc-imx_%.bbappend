FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += "file://0001-Release-2.patch \
                   file://0002-tc358746-Default-format-raw12.patch \
                   file://defconfig"
