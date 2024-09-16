#!/bin/sh

SWITCH_LOG_LOCATION=/mnt/iris/use_persistent_log_location
USER_DATA_LOG_DIR=/mnt/datastore/log
USER_DATA_LOG_DIR_LEGACY=/mnt/iris/log

# compatibility to new lvm layout: can be removed in major release 5.
if [ -d "$USER_DATA_LOG_DIR_LEGACY" ]; then
    mkdir -p "$USER_DATA_LOG_DIR"
    mv $USER_DATA_LOG_DIR_LEGACY/* $USER_DATA_LOG_DIR
    rm -rf $USER_DATA_LOG_DIR_LEGACY
fi

if [ -f "$SWITCH_LOG_LOCATION" ]; then
    mkdir -p "$USER_DATA_LOG_DIR"
    # Preserve and append current initramfs.log
    [ -f /var/volatile/log/initramfs.log ] && cat /var/volatile/log/initramfs.log >> "$USER_DATA_LOG_DIR/initramfs.log" && rm /var/volatile/log/initramfs.log
    mount "$USER_DATA_LOG_DIR" /var/volatile/log
elif [ -d "$USER_DATA_LOG_DIR" ]; then
    # Remove user data log dir except when the initramfs reports errors
    if [ "$(find $USER_DATA_LOG_DIR -mindepth 1 -maxdepth 1 | wc -l)" -ne 1 ] || [ ! -f "$USER_DATA_LOG_DIR/initramfs.log" ]; then
        rm -fr "$USER_DATA_LOG_DIR"
    fi
fi
