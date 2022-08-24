#!/bin/sh

TAG=$0

log() {
	logger -t $TAG $1
}

# pidofproc()
. /etc/init.d/functions

# Check if everything is still ok after update on first boot after reboot
PENDING_UPDATE=$(fw_printenv upgrade_available | awk -F'=' '{print $2}')
if [ "$PENDING_UPDATE" = "1" ]; then
	# Check if swupdate is still running
	if ! pidofproc swupdate; then
		log "Error: swupdate is not running"
		reboot
		exit 1
	fi

	# Use a temp file to write u-boot-env's in one go
	TMP_ENV_FILE="/tmp/reset_update_envs"
	printf "bootcount=0\nupgrade_available=\nustate=\n" > "$TMP_ENV_FILE"
	fw_setenv -s "$TMP_ENV_FILE"
	rm "$TMP_ENV_FILE"
	log "Update successful complete"
fi
