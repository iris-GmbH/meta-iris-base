#!/bin/sh

echo "NTP server list: $1";

NTPDIR="/bin/busybox"

ntpsrv_list=$1


if [ -n "$ntpsrv_list" ] ; then
	echo "The ntpsrv list is not empty."

	for i in $ntpsrv_list; do
		echo "start NTP daemon for ip: $i"
		#-g: This option allows ntpd to make large time adjustments, even if the system time is significantly different from the time reported by the NTP server.
		#-n: This option is used to run ntpd in the foreground without forking into the background.
		# It can be useful for seeing the output and status messages directly on the terminal.
		#-p: The -p option is used to specify the address of the NTP server to query.
		# &: This ampersand symbol at the end of the command is used to run the command in the background.
		# It allows the script or program to continue executing without waiting for the ntpd command to finish.
		$NTPDIR ntpd -g -p "$i"
		done
	else
		echo "The ntpsrv list is empty."
	fi
