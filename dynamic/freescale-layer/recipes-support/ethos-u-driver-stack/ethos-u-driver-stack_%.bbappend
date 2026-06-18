DEPENDS:remove = "python3-pybind11 python3-pybind11-native"

RDEPENDS:${PN} = "flatbuffers"
RDEPENDS:${PN}:remove = "python3-core python3-numpy python3-pillow"

do_compile() {
    cmake_do_compile
}

do_install() {
    cmake_do_install

    # Safety cleanup in case CMake still installs Python files
    rm -rf ${D}${PYTHON_SITEPACKAGES_DIR}
    rm -rf ${D}${libdir}/python*
}
