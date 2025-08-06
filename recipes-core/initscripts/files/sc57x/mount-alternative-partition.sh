#!/bin/sh

### BEGIN INIT INFO
# Provides:          mount-alternative-partition
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       mount the alternative mdtblock to /mnt/iris for extra space
### END INIT INFO


MOUNT_POINT="/mnt/iris"
SERVICE_DIR="$MOUNT_POINT/services"

get_partitions() {
    ACTIVE_PARTITION_NUM=$(readlink /dev/root | grep -o '[0-9]*')
    if [ "$ACTIVE_PARTITION_NUM" != "4" ] && [ "$ACTIVE_PARTITION_NUM" != "7" ]; then
        echo "Invalid root partition"
        return 1
    fi

    INACTIVE_PARTITION_NUM="4"
    if [ "$ACTIVE_PARTITION_NUM" = "4" ]; then
        INACTIVE_PARTITION_NUM=7
    fi

    INACTIVE_MTDBLOCK="/dev/mtdblock${INACTIVE_PARTITION_NUM}"
    return 0
}

start() {
    if mountpoint -q "$MOUNT_POINT"; then
        echo "$MOUNT_POINT is already mounted"
        return 0
    fi

    if ! get_partitions; then
        return 1
    fi

    mkdir -p "$MOUNT_POINT"
    if ! mount -t jffs2 -o rw,noatime "$INACTIVE_MTDBLOCK" "$MOUNT_POINT"; then
        echo "Failed to mount alternative partition"
        return 1
    fi

    if [ ! -d "$SERVICE_DIR" ]; then
        echo "Preparing alternative partition..."
        rm -rf "${MOUNT_POINT:?}/"*
        mkdir -p "$SERVICE_DIR"
    fi

    return 0
}

stop() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        echo "Not mounted"
        return 0
    fi

    if ! umount "$MOUNT_POINT"; then
        echo "Failed to unmount $MOUNT_POINT"
        return 1
    fi

    return 0
}

restart() {
    stop
    start
}

status() {
    if mountpoint -q "$MOUNT_POINT"; then
        echo "Alternative partition is mounted"
    else
        echo "Alternative partition is not mounted"
    fi
    return 0
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
esac

exit $?
