#!/bin/sh

CHRONY_DHCP_PATH_FILE="/var/run/chrony-dhcp/ntplist.sources"
CHRONY_DHCP_PATH="/var/run/chrony-dhcp"

ntpsrv_list=$1

if [ -n "$ntpsrv_list" ] ; then
	if [ ! -d "$CHRONY_DHCP_PATH" ]; then
		# Create the directory
		mkdir -p "$CHRONY_DHCP_PATH"
	fi
	
	if [ -e "$CHRONY_DHCP_PATH_FILE" ]; then
  		rm CHRONY_DHCP_PATH_FILE
	fi
  	touch "$CHRONY_DHCP_PATH_FILE"
	
	# Iterate over the server addresses and write them to the file for passing to chronyc later
	for server in $ntpsrv_list; do
		echo "writing $server to $CHRONY_DHCP_PATH_FILE - Script timeservice_dhcp_option_42.sh"
		echo "server" "$server" "iburst">> "$CHRONY_DHCP_PATH_FILE"
	done
	
	# Run chronyc reload sources to synchronize system time
	chronyc reload sources &

else
	echo "The ntpsrv list from dhcp server via option 42 is empty - nothing to do!."
fi
