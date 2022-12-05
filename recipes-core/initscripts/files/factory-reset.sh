#!/bin/sh

print_info() {
    [ $(("$1" & 0x0001)) -ne 0 ] && printf "GOOD "
    [ $(("$1" & 0x0002)) -ne 0 ] && printf "OPEN "
    [ $(("$1" & 0x0004)) -ne 0 ] && printf "SHORT "
    [ $(("$1" & 0x0008)) -ne 0 ] && printf "XSHORT1 "
    [ $(("$1" & 0x0010)) -ne 0 ] && printf "XSHORT2 "
    [ $(("$1" & 0x0020)) -ne 0 ] && printf "XSHORT3 "
    [ $(("$1" & 0x0040)) -ne 0 ] && printf "SIM "
    [ $(("$1" & 0x0080)) -ne 0 ] && printf "XSIM1 "
    [ $(("$1" & 0x0100)) -ne 0 ] && printf "XSIM2 "
    [ $(("$1" & 0x0200)) -ne 0 ] && printf "XSIM3 "
    [ $(("$1" & 0x0400)) -ne 0 ] && printf "BUSY "
}

# Store the result of the cable diagnostic in the variables pair_a and pair_b
cable_diagnostic() {
    echo "Start xshort check"

    # Check if phy is adin1200
    PHY_ID_ADIN1200=0x0283BC20
    id1=$(phytool read eth0/0x1/0x0002)
    id2=$(phytool read eth0/0x1/0x0003)
    id=$(printf '0x%.8X\n' "$(((id1 << 16) | id2))")
    [ "$((id))" -eq "$((PHY_ID_ADIN1200))" ] || return 1

    # Start cable diagnostic
    phytool write eth0/0x1/0x0017 0x1048 # Disbale link
    phytool write eth0/0x1/0x0012 0x0406 # Enable diagnostic clock

    retries=5
    while [ "$retries" -gt 0 ]; do
        phytool write eth0/0x1:0x1E/0xBA1B 0x0001 # Run diagnostic
        sleep 0.03
        pair_a=$(phytool read eth0/0x1:0x1E/0xBA1D) # Cable Diagnostics Results 0 Register
        pair_b=$(phytool read eth0/0x1:0x1E/0xBA1E) # Cable Diagnostics Results 1 Register
        [ $((pair_a)) -ne 0 ] && [ $((pair_b)) -ne 0 ] && break
        retries=$((retries-1))
    done
    [ "$retries" -gt 0 ] || return 1

    # Stop cable diagnostic and reset
    phytool write eth0/0x1/0x0017 0x3048 # Enable link
    phytool write eth0/0x1/0x0012 0x0402 # Disable diagnostic clock
    return 0
}

factory_reset() {
    # TODO: [APC-5256]: Remove customer certificates
    # TODO: [APC-5387]: Use HTTPS as default

    echo "Factory reset!"
    ln -sf /etc/nginx/sites-available/reverse_proxy_http.conf /mnt/iris/nginx/sites-enabled/default_server
    rm -f /mnt/iris/counter/config_customer*
    rm -f /mnt/iris/counter/webserver/preferences.json
    rm -f /mnt/iris/counter/webserver/authentication.sqlite
    rm -f /mnt/iris/logging/*.sqlite
}

# Skip check for cross pair short on nfs boot
if ! grep -q '/dev/nfs' /proc/cmdline; then
    if cable_diagnostic; then
        echo "  A: $pair_a $(print_info "$pair_a")"
        echo "  B: $pair_b $(print_info "$pair_b")"

        # 1/3 and 2/6 shorted
        XSHORT1=0x0008
        if [ $(("$pair_a" & "$XSHORT1")) -ne 0 ] && [ $(("$pair_b" & "$XSHORT1")) -ne 0 ]; then
            factory_reset
        fi
    fi
fi
