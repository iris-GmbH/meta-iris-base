#!/bin/sh

status_file="/tmp/ntp_sync_status.txt"

# If stratum is not set, default it to 16 (which means "not synchronized")
if [ -z "$stratum" ]; then
    stratum=16
fi

# Only update the file if stratum <= 16 (i.e., synchronized)
if [ "$stratum" -lt 16 ]; then
    # Write the relevant NTP environment variables to the file
    {
        # Output offset if set, otherwise mark as unknown
        [ -n "$offset" ] && echo "offset: $offset" || echo "offset: unknown"

        # Output the stratum value
        echo "stratum: $stratum"

        echo "NTP Status: Synchronized"

        # Use `ps | grep ntpd` to find the NTP server IP address
        ntp_server_ip=$(ps | grep '[n]tpd' | awk -F'-p ' '{print $2}' | awk '{print $1}')

        if [ -n "$ntp_server_ip" ]; then
            echo "NTP Server IP: $ntp_server_ip"
        else
            echo "NTP Server IP: unknown"
        fi

        # Add a message indicating successful processing
        echo "NTP Synchronization processed: $(date)"
    } > "$status_file"
else
     rm "$status_file"
     echo "NTP not synchronized"
fi

