RDEPENDS:${PN}:remove   = " \
    python3 \
    python3-numpy \
"

RDEPENDS_OPENCL = ""

PACKAGECONFIG:remove = "python-example"

do_compile:append() {
    ${CXX} ${CPPFLAGS} ${CXXFLAGS} \
        -fPIC \
        -I${S} \
        -c \
        ${S}/tensorflow/lite/tools/delegates/external_delegate_provider.cc \
        -o ${B}/external_delegate_provider.o

    ${AR} rcs \
        ${B}/libtflite_external_delegate_provider.a \
        ${B}/external_delegate_provider.o
}

do_install() {
    # install libraries
    install -d ${D}${libdir}
    for lib in ${B}/lib*.so*
    do
        cp --no-preserve=ownership -d $lib ${D}${libdir}
    done

    # install header files
    install -d ${D}${includedir}/tensorflow/lite
    cd ${S}/tensorflow/lite
    cp --parents \
        $(find . -name "*.h*") \
        ${D}${includedir}/tensorflow/lite

    # install version.h from core
    install -d ${D}${includedir}/tensorflow/core/public
    cp ${S}/tensorflow/core/public/version.h ${D}${includedir}/tensorflow/core/public

    # install ctstring_internal.h from core
    install -d ${D}${includedir}/tensorflow/core/platform
    cp ${S}/tensorflow/core/platform/ctstring_internal.h ${D}${includedir}/tensorflow/core/platform

    # install ctstring_internal.h from tsl
    install -d ${D}${includedir}/tsl/platform
    cp ${S}/third_party/xla/third_party/tsl/tsl/platform/ctstring_internal.h ${D}${includedir}/tsl/platform

    install -m 0644 \
        ${B}/libtflite_external_delegate_provider.a \
        ${D}${libdir}/
}

# Activates the Delegate-Provider-Infrastruktur in the TFLite-Tools
EXTRA_OECMAKE:append = " \
    -DTFLITE_BUILD_TOOLS_WITH_DELEGATES=ON \
"

FILES:${PN}-staticdev:append = " \
    ${libdir}/libtflite_external_delegate_provider.a \
"
