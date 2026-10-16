FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"
SRC_URI += " \
    file://0001-Remove-cmake-variables-for-bin-and-lib-directories.patch \
"

# Skip static libraries as they are not needed and will break the SDK as they are not included but are
# referenced in the cmake config of jsoncpp (if BUILD_STATIC_LIBS = ON)

EXTRA_OECMAKE += "-DBUILD_STATIC_LIBS=OFF"

