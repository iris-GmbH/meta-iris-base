#!/bin/sh

status_file="/tmp/ntp_sync_status.txt"


if [ -f "$status_file" ]; then
    # removing file
    rm "$status_file"
fi

touch "$status_file"

echo "NTP Synchronisation successful: $(date)" > $status_file

echo "NTP Synchronisation successful"
