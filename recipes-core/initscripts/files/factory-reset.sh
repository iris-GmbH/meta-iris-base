#!/bin/sh

. /usr/share/factory-reset/factory-reset-functions || exit 1

FORCE=0
LAZY=0

while getopts ":lf" options; do
    case "${options}" in
        f) FORCE=1 ;;
        l) LAZY=1 ;;
        *) echo "Usage: $0 [-f] [-l]" >&2; exit 1 ;;
    esac
done

# Check if the factory reset is forced or if the reset flag is set
if [ "$FORCE" -eq 1 ] || is_flag_set; then
    factory_reset
    exit 0
fi

# Set a flag to perform a factory reset on the next reboot
if [ "$LAZY" -eq 1 ]; then
    set_flag
    exit 0
fi

# Skip rj45 short check on nfs boot
if ! grep -q '/dev/nfs' /proc/cmdline; then
    short_detected && factory_reset || exit 1
fi
