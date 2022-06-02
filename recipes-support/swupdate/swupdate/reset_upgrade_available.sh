#!/bin/sh

PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')

if [ "$PENDING_UPDATE" = "1" ]; then
	# Use a temp file to write u-boot-env's in one go
	TMP_ENV_FILE="/tmp/reset_update_envs"
	printf "bootcount=0\nupgrade_available=\nustate=\n" > "$TMP_ENV_FILE"
	fw_setenv -s "$TMP_ENV_FILE"
	rm "$TMP_ENV_FILE"
	echo "Update successful complete"
fi
