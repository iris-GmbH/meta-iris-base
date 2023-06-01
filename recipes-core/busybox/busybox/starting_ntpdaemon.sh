#!/bin/sh

echo "NTP server list for starting_ntpdaemon.sh: $1";

ntpsrv_list=$1

if [ -n "$ntpsrv_list" ] ; then
	echo "The ntpsrv list is not empty."

	# Iterate over the server addresses and pass them to chronyc
	for server in $ntpsrv_list; do
		echo "Add ntp server $server."
		chronyc add server "$server" prefer
	done
else
		echo "The ntpsrv list is empty."
fi
