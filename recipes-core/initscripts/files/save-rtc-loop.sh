#!/bin/sh

LOCKFILE=/run/save-rtc-loop.lock

# Only start once
if [ ! -e "$LOCKFILE" ];
then
	touch "$LOCKFILE"
	# Call save rtc regularly
	watch -n 1800 -t /etc/init.d/save-rtc.sh > /dev/null &
fi
