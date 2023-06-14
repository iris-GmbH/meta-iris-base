#!/bin/sh

MOUNTPOINT="/mnt/iris/"
IDENTITY_DIR="/mnt/iris/identity"
MOUNT_GROUP="irma_userdata"

# No "chown -R" because we don't want to touch subdirs
chown root:"$MOUNT_GROUP" "$MOUNTPOINT" && chmod 0775 "$MOUNTPOINT"

# Restrict access to identity files
chown root:root -R "$IDENTITY_DIR"
chmod 0400 -R "$IDENTITY_DIR"
chmod u+x "$IDENTITY_DIR"
