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
    echo "Factory-Reset is triggered by flag file"
    factory_reset
    exit 0
fi

# Set a flag to perform a factory reset on the next reboot
if [ "$LAZY" -eq 1 ]; then
    set_flag
    exit 0
fi

if grep -q '/dev/nfs' /proc/cmdline; then
    echo "Skip factory reset short check on NFS boot!"
    exit 0
fi

# NOTE: Only perform short check if link ready and down!
carrier_file="/sys/class/net/eth0/carrier"
carrier=""
for i in $(seq 10); do
    if [ ! -r "$carrier_file" ]; then
        echo "WARN: Carrier file not present or not readable"
    else
        carrier=`cat "$carrier_file" 2>/dev/null`
        case "$carrier" in
            1) break ;;
            0) echo "Link is down (retrying...)" ;;
            *) echo "WARN: Carrier file not ready" ;;
        esac
    fi
    echo "Wait for carrier .. ($i)"
    sleep 1
done

case "$carrier" in
    1) echo "Link is up: Skip eth0 short check" ;;
    0) echo "Link is down: Perform eth0 short check"; short_detected && factory_reset || exit 1 ;;
    *) echo "WARN: Carrier status unknown"; exit 1 ;;
esac
