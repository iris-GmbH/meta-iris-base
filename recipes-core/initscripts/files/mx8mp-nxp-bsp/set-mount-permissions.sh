#!/bin/sh

MOUNTPOINT="/mnt/iris/"
IDENTITY_DIR="/mnt/iris/identity"
MOUNT_GROUP="irma_userdata"
IDENTITY_GROUP="irma_identity"
SWUPDATE_KEY="/mnt/iris/swupdate/encryption.key"

# No "chown -R" because we don't want to touch subdirs
chown root:"$MOUNT_GROUP" "$MOUNTPOINT" && chmod 0775 "$MOUNTPOINT"

# Restrict access to identity files
chown root:"$IDENTITY_GROUP" -R "$IDENTITY_DIR"
chmod 0440 -R "$IDENTITY_DIR"
chmod ug+x "$IDENTITY_DIR"

# Restrict access to swupdate encryption key
chown root:root "$SWUPDATE_KEY"
chmod 0400 "$SWUPDATE_KEY"
