#!/bin/sh

. /etc/init.d/factory-reset-functions || exit 1

FORCE=0
while getopts ":fr" options; do
    case "${options}" in
        f) FORCE=1 ;;
        *) echo "Usage: $0 [-f]" >&2; exit 1 ;;
    esac
done

# Check if the factory reset is forced
if [ "$FORCE" -eq 1 ]; then
    factory_reset
    exit 0
fi

# Skip rj45 short check on nfs boot
if ! grep -q '/dev/nfs' /proc/cmdline; then
    short_detected && factory_reset || exit 1
fi
