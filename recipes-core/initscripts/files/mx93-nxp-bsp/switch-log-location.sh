#!/bin/sh

SWITCH_LOG_LOCATION=/mnt/iris/irma6webserver/use_persistent_log_location
USER_DATA_LOG_DIR=/mnt/datastore/log

if [ -f "$SWITCH_LOG_LOCATION" ]; then
    mkdir -p "$USER_DATA_LOG_DIR"
    mount "$USER_DATA_LOG_DIR" /var/volatile/log
elif [ -d "$USER_DATA_LOG_DIR" ]; then
    rm -fr "$USER_DATA_LOG_DIR"
fi
