#!/bin/sh

BUSYBOX_PATH="/bin/busybox"

ntpsrv_list=$1

if [ -n "$ntpsrv_list" ] ; then
	echo "The ntpsrv list for starting ntpd - script timeservice_dhcp_option_42.sh"

	# Checking if ntpd processes are already running and kill it/them
	NTP_PID=$(pgrep -f "/bin/busybox ntpd")
	if [ -n "$NTP_PID" ]; then
		echo "ntpd is running with PIDs: $NTP_PID - kill it"
		kill $NTP_PID
	fi

	# Replace IP addresses with "-p ip" using sed
	ntpsrv_list_with_peer_param=$(echo "$ntpsrv_list" | sed 's/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/-p &/g')

	#-g: This option allows ntpd to make large time adjustments, even if the system time is significantly different from the time reported by the NTP server.
	#-p: The -p option is used to specify the address of the NTP server to query.
	$BUSYBOX_PATH ntpd -g $ntpsrv_list_with_peer_param
else
	echo "The ntpsrv list from dhcp option 42 is empty- nothing to do - script timeservice_dhcp_option_42.sh"
fi
