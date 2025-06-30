#!/bin/sh

CORE_PATH="/var/log/coredumps"
CORE_LOCK="/tmp/coredumps.lock" # lock shared with Webserver

PID="$1"

# no file truncation, core dumps can only be disabled or enabled
# anything different than 0 means enabled
# shellcheck disable=SC3045 # (ulimit is available)
core_limit=$(grep "Max core file size" "/proc/$PID/limits" | awk '{print $5}')
if [ "$core_limit" = "0" ]; then
    exit 1
fi

# Get process name
PROC_NAME=$(ps -p "${PID}" -o comm= 2>/dev/null | head -1)
if [ -z "$PROC_NAME" ]; then
    PROC_NAME="unknown"
fi

COMPRESSED_CORE="${CORE_PATH}/core.${PROC_NAME}.${PID}.gz"

(
    # acquire file lock or timeout after 30s
    flock -w 30 9 || {
        logger "Could not acquire lock on ${CORE_LOCK} for core dump of ${PROC_NAME}"
        exit 1
    }

    # Delete old compressed cores for this process name
    find "${CORE_PATH}" -name "core.${PROC_NAME}.*.gz" -type f -print0 2>/dev/null | xargs -0 rm -f

    # create empty file with correct permissions for var_log
    touch "${COMPRESSED_CORE}"
    chgrp var_log "${COMPRESSED_CORE}" 2>/dev/null
    chmod 640 "${COMPRESSED_CORE}"

    # compress stdin into core file
    if gzip > "${COMPRESSED_CORE}"; then    
        logger "Core dump created for ${PROC_NAME}: ${COMPRESSED_CORE}"
    else
        logger "Failed to create compressed core dump for PID ${PID} (${PROC_NAME}): ${COMPRESSED_CORE}"
        rm -f "${COMPRESSED_CORE}" 2>/dev/null
    fi


) 9>${CORE_LOCK}