FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"

SRC_URI += "\
	file://0001-add-ipv6-support-to-seasocks.patch \
	file://0002-Connection.cpp-Forbid-empty-static-root-path.patch \
	file://0003-Remove-embedded-content.patch \
"
