#!/bin/bash

echo "NTP server list: $1";


ntpsrv_list=$1

if [ -n "$ntpsrv_list" ] ; then
	echo "The ntpsrv list is not empty."

	for i in $ntpsrv_list; do
		echo "server $ntpsrv_list" >> /mnt/iris/chrony/chrony.conf
	done
	sudo systemctl start chrony
else
		echo "The ntpsrv list is empty."
fi
