#!/bin/sh

CORE_PATH_ENABLE_FLAG="/mnt/iris/irma6webserver/enable_core_dump"

enable_core_dump() {
    ! [ -f $CORE_PATH_ENABLE_FLAG ] && return

    # enable shared/private mappings
    echo 0x1F > /proc/self/coredump_filter

    # core-dump-handler.sh does not have file size limitation logic
    # anything above 0 will create a core
    # shellcheck disable=SC3045 # (ulimit is available)
    ulimit -c unlimited
}
