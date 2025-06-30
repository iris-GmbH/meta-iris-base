#!/bin/sh

### BEGIN INIT INFO
# Provides:          core-dump-handler
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Core dump handler configuration
# Description:       Configure core dump handling with compression and cleanup
### END INIT INFO

CORE_PATH="/var/log/coredumps"
HANDLER_PATH="/usr/share/core-dump/core-dump-handler.sh"
CORE_PATH_ENABLE_FLAG="/mnt/iris/irma6webserver/enable_core_dump"
CORE_LOCK="/tmp/coredumps.lock"

remove_core_dumps() {
    rm -f $CORE_PATH/*
}

start() {
    if ! [ -f $CORE_PATH_ENABLE_FLAG ]; then
        echo "Core dumps are disabled"
        remove_core_dumps # remove old cores
        return 0
    fi

    echo "Starting core dump handler configuration..."

    mkdir -p "$CORE_PATH" 
    chmod 0775 "$CORE_PATH"
    chown -R root:var_log "$CORE_PATH"

    touch $CORE_LOCK
    chmod 0666 $CORE_LOCK

    # Set core pattern with custom handler
    if [ -x "$HANDLER_PATH" ]; then
        echo "|$HANDLER_PATH %P" > /proc/sys/kernel/core_pattern
        echo "Core dump handler configured successfully"
    else
        echo "Error: Handler script not found at $HANDLER_PATH"
        return 1
    fi

    sysctl -w fs.suid_dumpable=2 > /dev/null
}

stop() {
    # pass
    :
}

status() {
    echo "Core dump configuration status:"
    if ! [ -f $CORE_PATH_ENABLE_FLAG ]; then
        echo "Core dumps are disabled"
        return 0
    fi
    echo "Current core pattern: $(cat /proc/sys/kernel/core_pattern)"
    echo "fs.suid_dumpable: $(sysctl -n fs.suid_dumpable)"
    echo "Core dump directory: $CORE_PATH"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit $?
