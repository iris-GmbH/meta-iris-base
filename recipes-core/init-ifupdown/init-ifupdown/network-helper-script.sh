#!/bin/sh

# The function setupNetworkInterfaces configures the eth0 Linux network interface as follows
#
# eth0.0: Interface 1: is the customer-specific network adapter. It can be configured to work as a DHCP client or as a network adapter in static IP mode
# eth0.1: Interface 2: is the service network adapter: Is is always in static IP mode, whereby the IP address is generated from the Mac address
#
# The static ip address for the interface eth0:0 is taken from the /etc/counter/config_customer.json file
# If no ip address or mode can be found, the adapter is configured to work as a DHCP client

ENABLE_SERVICE_ADAPTER=true # service mac based ip adapter
CUSTOMERMODE=1 # 1=dhcp (default), 0=static 
CUSTOMERIP=""
CUSTOMERNETMASK=""
CUSTOMERGATEWAY=""
CUSTOMERDNS=""
CUSTOMDHCP61ACIVATED=""
CUSTOMDHCP61CLIENTIDENTIFIER=""
CUSTOMDHCP61ARGUMENT=""
CUSTOMERNETWORKFILE="/etc/counter/config_customer.json"
json=""

# Check if interface is up
# 1: interface e.g. eth0, eth0:1, eth0:2
# return 0 on success, 1 otherwise
iface_is_down() {
    ifconfig "$1" | grep -q 'inet ' && return 1 || return 0
}

# Output octet of an ip address at position
# 1: ip address
# 2: octet 1-4 e.g. 4 for x in 0.0.0.x
getOctet() {
    echo "$1" | cut -d. -f"$2"
}

validateIp() {
    if expr "$1" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
        # Disallow 0.x.x.x
        if [ "$(echo "$1" | cut -d. -f1)" -lt 1 ]; then
            return 1
        fi
        # Any address with a number above 255 in it is invalid
        for i in 1 2 3 4; do
            if [ "$(getOctet "$1" $i)" -gt 255 ]; then
                return 1
            fi
        done
        return 0
    fi
    
    return 1
}

createIpFromMAC() {
    # read mac from address, extract last bytes and generate ip address
    read -r MAC </sys/class/net/eth0/address
    MAC2=$(printf '%s' "$MAC" | tr ':' ' ')
    MAC5=$(echo "$MAC2" | awk '{ print $5 }')
    MAC6=$(echo "$MAC2" | awk '{ print $6 }')
    echo "172.16.$((0x${MAC5})).$((0x${MAC6}))"
}

parameterExists() {
    [ -z "$json" ] && return 1
    param=$(echo "$json" | sed -rn 's/.*"('"$1"')"\s*:.*/\1/p')
    if [ "$param" != "" ]; then
        return 0
    else
        return 1
    fi
}

getParameter() {
    [ -z "$json" ] && return 1
    val=$(echo "$json" | sed -rn 's/.*"'"$1"'"\s*:\s*\{\s*"value"\s*:\s*([^,]*).*/\1/p')

    # compatibility for old v1.0 ipv4 parameters - "value": {"value": "255.254.0.0"}
    if echo "$val" | grep -q '"value"'; then
        val=$(echo "$val" | sed -n 's/.*"value"\s*:\s*"\([^"]*\)".*/\1/p')
    fi

    echo "$val" | sed 's/^"//' | sed 's/"$//' # remove leading/trailing double quotes
}

setCommunicationParameters() {
    echo "Configuration:"
    if parameterExists "pa\.communication\.enableserviceip"; then
        ENABLE_SERVICE_ADAPTER=$(getParameter "pa\.communication\.enableserviceip")
        echo "  pa.communication.enableserviceip:" "$ENABLE_SERVICE_ADAPTER"
    fi
    if parameterExists "pa\.communication\.ipaddressconfiguration"; then
        CUSTOMERMODE=$(getParameter "pa\.communication\.ipaddressconfiguration")
        echo "  pa.communication.ipaddressconfiguration:" "$CUSTOMERMODE"
    fi
    if parameterExists "pa\.communication\.ipaddr"; then
        CUSTOMERIP=$(getParameter "pa\.communication\.ipaddr")
        echo "  pa.communication.ipaddr:" "$CUSTOMERIP"
    fi
    if parameterExists "pa\.communication\.netmask"; then
        CUSTOMERNETMASK=$(getParameter "pa\.communication\.netmask")
        echo "  pa.communication.netmask:" "$CUSTOMERNETMASK"
    fi
    if parameterExists "pa\.communication\.gateway"; then
        CUSTOMERGATEWAY=$(getParameter "pa\.communication\.gateway")
        echo "  pa.communication.gateway:" "$CUSTOMERGATEWAY"
    fi
    if parameterExists "pa\.communication\.dns"; then
        CUSTOMERDNS=$(getParameter "pa\.communication\.dns")
        echo "  pa.communication.dns:" "$CUSTOMERDNS"
    fi
    if parameterExists "pa\.communication\.dhcp_usecustomoption61"; then
        CUSTOMDHCP61ACIVATED=$(getParameter "pa\.communication\.dhcp_usecustomoption61")
        echo "  pa.communication.dhcp_usecustomoption61:" "$CUSTOMDHCP61ACIVATED"
    fi
    if parameterExists "pa\.communication\.dhcp_customoption61clientidentifier"; then
        CUSTOMDHCP61CLIENTIDENTIFIER=$(getParameter "pa\.communication\.dhcp_customoption61clientidentifier")
        echo "  pa.communication.dhcp_customoption61clientidentifier:" \""$CUSTOMDHCP61CLIENTIDENTIFIER\""
    fi
}

createServiceAdapter() {
    iface_is_down eth0 && ifconfig eth0 up

    # add virtual network adapter with ip generated from mac
    # check if address does not end with ".0.0".
    # ".x.0" and ".0.x" is allowed
    if [ "$ENABLE_SERVICE_ADAPTER" != false ]; then
        service_ip=$(createIpFromMAC)
        if validateIp "$service_ip" && { [ "$(getOctet "$service_ip" 3)" -ne 0 ] || [ "$(getOctet "$service_ip" 4)" -ne 0 ]; }; then
            # netmask 255.254.0.0 (range 172.16.0.0 to 172.17.255.255) allows service Hosts on the same subnet
            # Sensor (172.16.x.y) <-> Host (172.17.x.y) -> same subnet and no ip collision possibility
            iface_is_down eth0:1 && ifconfig eth0:1 "$service_ip" netmask 255.254.0.0
            echo "Interface 1: using IP: $service_ip"
        fi
    fi

    # Add maintenance virtual network adapter eth0:2 (only available in Maintenance FW)
    if grep -iq maintenance /etc/os-release; then
       iface_is_down eth0:2 && ifconfig eth0:2 192.168.240.254 netmask 255.255.254.0
       echo "Interface 2: using IP: 192.168.240.254"
    fi
}

setDhcpOption61Argument() {
    if [ "$CUSTOMDHCP61ACIVATED" = true ]; then
        # removes the quotes at the beginning and the end with sed
        clientIdentifier=$(printf "%s" "$CUSTOMDHCP61CLIENTIDENTIFIER" | sed 's/\(^.\)\|\(.$\)//g' )
        if [ ! "$clientIdentifier" ]; then
            echo "Custom DHCP option 61 is enabled but custom client identifier is empty. Custom option is not used."
            return
        fi
        clientIdentifier=$(printf "%s" "$clientIdentifier" | hexdump  -v -e '/1 "%02X"')
        if ! expr "$clientIdentifier" : "[0-9A-Fa-f]" > /dev/null ; then
            echo "Custom client identifier results in malformed hex string: \"$clientIdentifier\". Custom option is not used."
            return
        fi
        CUSTOMDHCP61ARGUMENT=$(echo "-x 0x3d:00$clientIdentifier")
        return
    fi
}

setupDHCP() {
    # Do not modify interface when running from nfs
    if grep -q "root=/dev/nfs" /proc/cmdline; then
        echo "Interface is already used for nfs"
    # check if udhcpc is already running and start dhcp client
    elif [ -f "/var/run/udhcpc.eth0.pid" ]; then
        echo "DHCP Client is already running"
    else
        setDhcpOption61Argument
        udhcpc -R -b -p /var/run/udhcpc.eth0.pid -i eth0 "$CUSTOMDHCP61ARGUMENT"
    fi
}

createCustomerAdapter() {
    # add virtual adapter from customer configuration
    # validate configuration, if something fails, fall back to dhcp
    # gateway is treated as optional
    if [ "$CUSTOMERMODE" -eq 0 ]; then
        if validateIp "$CUSTOMERIP" &&  validateIp "$CUSTOMERNETMASK"; then
            if ifconfig eth0 "$CUSTOMERIP" netmask "$CUSTOMERNETMASK"; then
                echo "Interface eth0 reconfigured. IP:$CUSTOMERIP, NETMASK:$CUSTOMERNETMASK"

                if validateIp "$CUSTOMERGATEWAY"; then
                    route add default gw "$CUSTOMERGATEWAY" eth0
                    echo "$CUSTOMERGATEWAY Gateway route added for eth0"
                fi
                if validateIp "$CUSTOMERDNS"; then
                    # Add DNS-Server
                    echo "nameserver $CUSTOMERDNS" > /etc/resolv.conf
                fi
                return
            fi
        fi
    fi
    setupDHCP
}

readConfigCustomerJson() {
    if [ ! -r "$CUSTOMERNETWORKFILE" ]; then
        echo "$0: Can not read $CUSTOMERNETWORKFILE"
        return 1
    fi
    # Convert config to single line json so we can regex it with sed
    json=$(tr -d '\n' < "$CUSTOMERNETWORKFILE")
}

setupNetworkInterfaces() {
    readConfigCustomerJson
    setCommunicationParameters
    createCustomerAdapter
    createServiceAdapter
}
