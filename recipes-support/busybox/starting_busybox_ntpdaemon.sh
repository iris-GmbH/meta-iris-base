#!/bin/bash

echo "NTP server list: $1";

NTPDIR="/bin/busybox"

ntpsrv_list=$1

if [ -n "$ntpsrv_list" ] ; then
	echo "The ntpsrv list is not empty."

	for i in $ntpsrv_list; do
		echo "start NTP daemon for ip: $i"
		$NTPDIR ntpd -n -p $i
		done
	else
		echo "The ntpsrv list is empty."
	fi
