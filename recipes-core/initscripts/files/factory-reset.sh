#!/bin/sh

cable_is_shorted=0

adin1200_print_info() {
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

# ADIN1200 short detection
# Test if the cable pairs 1/2 and 3/6 are shorted and store the result in the
# variable: cable_is_shorted: 0: Not shorted, 1: Shorted
# returns 0 on success, 1 otherwise
adin1200_cable_diagnostic() {
    echo "Start ADIN1200 Short check"

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

    echo "  A: $pair_a $(adin1200_print_info "$pair_a")"
    echo "  B: $pair_b $(adin1200_print_info "$pair_b")"

    # 1/2 and 3/6 shorted
    SHORT=0x0004
    if [ $(("$pair_a" & "$SHORT")) -ne 0 ] && [ $(("$pair_b" & "$SHORT")) -ne 0 ]; then
        cable_is_shorted=1
    fi

    return 0
}

ksz8081_print_info() {
    [ $1 -eq 0 ] && printf "GOOD"
    [ $1 -eq 1 ] && printf "OPEN"
    [ $1 -eq 2 ] && printf "SHORT"
    [ $1 -eq 3 ] && printf "TEST FAILED"
}

ksz8081_cable_test_wait_for_completion() {
    j=5
    while [ "$j" -gt 0 ]; do
        usleep 30
        status=$(phytool read eth0/0x1/0x001D)
        [ $(($status & 0x8000)) -ne 0 ] || break
        j=$((j-1))
    done
    [ "$j" -gt 0 ] || { echo "[ERROR] self cleared failed -> timeout: $status"; return 1; }
    return 0
}

ksz8081_read_one_pair() {
	# set mdi/mdix
	if [ "$1" -eq 0 ]; then
    	phytool write eth0/0x1/0x001F 0xA100 # Disbale auto MDI/MDI-X + set MDI
    else
    	phytool write eth0/0x1/0x001F 0xE100 # Disbale auto MDI/MDI-X + set MDIX
    fi
    phytool write eth0/0x1/0x001D 0x8000 # Start cable diagnostic
    ksz8081_cable_test_wait_for_completion || return 1

    ret=$((($status>>13)&0x3))
    [ "$ret" -eq 3 ] && return 1 # test failed
    echo "$ret"
    return 0
}

# KSZ8081 short detection
# Test if the cable pairs 1/2 and 3/6 are shorted and store the result in the
# variable: cable_is_shorted: 0: Not shorted, 1: Shorted
# returns 0 on success, 1 otherwise
ksz8081_cable_diagnostic() {
    # Prepare
    phytool write eth0/0x1/0x0000 0x0100 # Disable Autonegotiation + 10Mbps

	i=0
	while [ $i -lt 20 ]; do
		# ksz8081_read_one_pair 0: test pair 1/2
        # ksz8081_read_one_pair 1: test pair 3/6
        pair_a=$(ksz8081_read_one_pair 0) && pair_b=$(ksz8081_read_one_pair 1) && break
		i=$(( i + 1 ))
	done

    # Reset
    phytool write eth0/0x1/0x001F 0x8100 # Enable auto MDI/MDI-X
    phytool write eth0/0x1/0x0000 0x3100 # Enable autonegotiation + 100Mbps

    [ "$i" -lt 20 ] && return 0 || { echo "Max retries reached"; return 1; }
    
    echo "  A: $pair_a $(ksz8081_print_info "$pair_a")"
    echo "  B: $pair_b $(ksz8081_print_info "$pair_b")"

    if [ "$pair_a" -eq 2 ] && [ "$pair_b" -eq 2 ]; then
        cable_is_shorted=1
    fi
}

factory_reset() {
    # TODO: [APC-5256]: Remove customer certificates
    # TODO: [APC-5387]: Use HTTPS as default

    echo "Factory reset!"

    MACHINE=$(grep 'MACHINE' < /etc/os-release | cut -f2 -d\")
    case "$MACHINE" in
        "imx8mp-irma6r2")
            ln -sf /etc/nginx/sites-available/reverse_proxy_http.conf /mnt/iris/nginx/sites-enabled/default_server
            rm -f /mnt/iris/counter/config_customer*
            rm -f /mnt/iris/counter/webserver/preferences.json
            rm -f /mnt/iris/counter/webserver/authentication.sqlite
            rm -f /mnt/iris/logging/*.sqlite
            ;;
        "sc573-gen6")
            echo "todo: rm files here"
            ;;
        *)
            echo "Error: MACHINE not supported"
            exit 1
            ;;
    esac
}

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

# Skip check for cross pair short on nfs boot
if ! grep -q '/dev/nfs' /proc/cmdline; then
    id1=$(phytool read eth0/0x1/0x0002)
    id2=$(phytool read eth0/0x1/0x0003)
    id=$(printf '0x%.8X\n' "$(((id1 << 16) | id2))")
    #[ "$((id))" -eq "$((PHY_ID_ADIN1200))" ] || return 1

    PHY_ID_ADIN1200=0x0283BC20
    PHY_ID_KSZ8081=0x0283BC20

    case "$id" in
        "$PHY_ID_ADIN1200")
            adin1200_cable_diagnostic || { echo "Error: ADIN1200 cable diagnostic failed"; exit 1; }
            ;;
        "$PHY_ID_KSZ8081")
            ksz8081_cable_diagnostic || { echo "Error: KSZ8081 cable diagnostic failed"; exit 1; }
            ;;
        *)
            echo "Error: PHY-ID: $id is not supported"
            exit 1
            ;;
    esac

    if [ "$cable_is_shorted" -eq 1 ]; then
		factory_reset
    fi
fi
