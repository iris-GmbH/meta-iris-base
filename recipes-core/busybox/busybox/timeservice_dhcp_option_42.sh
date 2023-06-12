#!/bin/sh

CHRONY_DHCP_PATH_FILE="/var/run/chrony-dhcp/ntplist.sources"
CHRONY_DHCP_PATH="/var/run/chrony-dhcp"

ntpsrv_list=$1

if [ -n "$ntpsrv_list" ] ; then
	echo "The ntpsrv list is not empty."

	if [ -d "$CHRONY_DHCP_PATH" ]; then
		echo "Directory already exists."
	else
		# Create the directory
		mkdir -p "$CHRONY_DHCP_PATH"
	fi
	
	if [ -e "$CHRONY_DHCP_PATH_FILE" ]; then
  		echo "File already exists - but should not - removing"
  		rm CHRONY_DHCP_PATH_FILE
	else
  		echo "File does not exist. Creating..."
  		touch "$CHRONY_DHCP_PATH_FILE"
	fi
	
	# Iterate over the server addresses and write them to the file for passing to chronyc later
	for server in $ntpsrv_list; do
		echo "writing $server to $CHRONY_DHCP_PATH_FILE."
		echo "server" "$server" "iburst">> "$CHRONY_DHCP_PATH_FILE"
	done
else
	echo "The ntpsrv list is empty - nothing to do!."
fi
