#!/bin/sh

MOUNTPOINT="/mnt/iris/"
MOUNT_GROUP="irma_userdata"

# No "chown -R" because we don't want to touch subdirs
[ "$(stat -c '%g' $MOUNTPOINT)" = 0 ] && chown :"$MOUNT_GROUP" "$MOUNTPOINT" && chmod 0775 "$MOUNTPOINT"
