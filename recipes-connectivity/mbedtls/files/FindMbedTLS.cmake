# SPDX-License-Identifier: MIT
# Copyright (C) 2025, iris-GmbH intelligent sensors <mail@iris-sensing.com>

find_path(MBEDTLS_INCLUDE_DIR "mbedtls/ssl.h")
find_library(MBEDTLS_LIBRARY mbedtls)
find_library(MBEDX509_LIBRARY mbedx509)
find_library(MBEDCRYPTO_LIBRARY mbedcrypto)

unset(MBEDTLS_VERSION CACHE)

if(MBEDTLS_INCLUDE_DIR)
    set(_version_file "${MBEDTLS_INCLUDE_DIR}/mbedtls/build_info.h")
   if(EXISTS "${_version_file}")
       file(STRINGS "${_version_file}" _version_line
         REGEX "#[ \t]*define[ \t]+MBEDTLS_VERSION_STRING[ \t]+\"[0-9.]+\"")
           if(_version_line)
               string(REGEX REPLACE ".*MBEDTLS_VERSION_STRING[ \t]+\"([0-9.]+)\".*" "\\1" MBEDTLS_VERSION "${_version_line}")
           endif()
   endif()
endif()

set(MBEDTLS_LIBRARIES ${MBEDTLS_LIBRARY} ${MBEDX509_LIBRARY} ${MBEDCRYPTO_LIBRARY})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MbedTLS
    REQUIRED_VARS
        MBEDTLS_INCLUDE_DIR
        MBEDTLS_LIBRARY
        MBEDX509_LIBRARY
        MBEDCRYPTO_LIBRARY
    VERSION_VAR
        MBEDTLS_VERSION
)
