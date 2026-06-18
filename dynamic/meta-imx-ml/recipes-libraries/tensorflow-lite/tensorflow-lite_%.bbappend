RDEPENDS:${PN}:remove   = " \
    python3 \
    python3-numpy \
    ${RDEPENDS_OPENCL} \
"

PACKAGECONFIG:remove = "python-example"

do_install:append() {
    rm -rf ${D}${PYTHON_SITEPACKAGES_DIR}
    rm -f ${D}${bindir}/${PN}-${PV}/examples/label_image.py
}

#EXTRA_OECMAKE:remove = "-DTFLITE_PYTHON_WRAPPER_BUILD_CMAKE2=on"
