RDEPENDS:${PN}:remove = "python3-core flatbuffers python3-numpy python3-pillow"

do_compile() {
    cmake_do_compile
}

do_install() {
    cmake_do_install
}
