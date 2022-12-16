#!/bin/sh

. /usr/share/factory-reset/factory-reset-functions || exit 1
[ -n "$LAZY_RESET_FLAG" ] || { echo "Error: Filename LAZY_RESET_FLAG is not set"; exit 1; }

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
if [ "$FORCE" -eq 1 ] || [ -f "$LAZY_RESET_FLAG" ]; then
    factory_reset
    rm -f "$LAZY_RESET_FLAG"
    exit 0
fi

# Touch a file to perform a factory reset on the next reboot
if [ "$LAZY" -eq 1 ]; then
    touch "$LAZY_RESET_FLAG"
    exit 0
fi

# Skip rj45 short check on nfs boot
if ! grep -q '/dev/nfs' /proc/cmdline; then
    short_detected && factory_reset || exit 1
fi
