#!/usr/bin/env bash

# the script will immediately exit when errors occur: -e
# or unset varibles: u
# and  ensure that errors in any part of a pipeline are properly propagated: o pipefail
set -euo pipefail

MNT_IRIS_UDHCP_SYSLOG_REMOTE_CONFFILE="/mnt/iris/rsyslog/syslog-remotes-udhcp.conf"

# the option is read as a enviroment variable passed by udhcp client
echo "option 7: ${1:?}"
hex_value=$1
ip_list=""
use_udp_active=false

# reading the option 240 (hex value) and convert it into a list of syslog server iPs
while [ -n "$hex_value" ]; do
	octet_pair="${hex_value:0:8}"
	first_octet=$(printf "%d" "0x${octet_pair:0:2}")
	second_octet=$(printf "%d" "0x${octet_pair:2:2}")
	third_octet=$(printf "%d" "0x${octet_pair:4:2}")
	fourth_octet=$(printf "%d" "0x${octet_pair:6:2}")

	ip_address="$first_octet.$second_octet.$third_octet.$fourth_octet"
	ip_list="$ip_list $ip_address"

	# extracting a substring starting from the 9th character (since indexing starts at 0)
	hex_value="${hex_value:8}"
done

echo "syslog ip list is: $ip_list"

echo "Reading configuration"

parameterExists(){
  param=$(echo "$json" | sed -rn 's/.*"('"$1"')"\s*:.*/\1/p')
  if [ "$param" = "" ]; then
    false
  else
    true
  fi
}

getParameter(){
  val=$(echo "$json" | sed -rn 's/.*"'"$1"'"\s*:\s*\{\s*"value"\s*:\s*([^,]*).*/\1/p')
  echo "$val"
}



CUSTOMERCONFIGFILE="/etc/counter/config_customer.json"
if [ ! -f "$CUSTOMERCONFIGFILE" ]; then
    echo "$0: Can not read $CUSTOMERCONFIGFILE" 
    exit 0
fi


CUSTOMERCONFIGFILE="/etc/counter/config_customer.json"
if [ ! -f "$CUSTOMERCONFIGFILE" ]; then
    echo "$0: Can not read $CUSTOMERCONFIGFILE"
else
	# Convert config to single line json so we can regex it with sed
	json=$(cat "$CUSTOMERCONFIGFILE" | tr '\n' ' ')

	if parameterExists "pa.logging.syslog.useudp"; then
   		use_udp_active=$(getParameter "pa\.logging\.syslog\.useudp")
   		echo "pa.logging.syslog.useudp:" "$use_udp_active"
	fi
fi


if [ -e "$MNT_IRIS_UDHCP_SYSLOG_REMOTE_CONFFILE" ]; then
	rm "$MNT_IRIS_UDHCP_SYSLOG_REMOTE_CONFFILE"
fi

if [ -n "$ip_list" ]; then
	touch "$MNT_IRIS_UDHCP_SYSLOG_REMOTE_CONFFILE"

	# Iterate over the server IPs and write them to the file for passing to rsyslog
	for server in $ip_list; do
		echo "writing $server to $MNT_IRIS_UDHCP_SYSLOG_REMOTE_CONFFILE - script udhcp_custom_syslog_option.sh"

		if [ "$use_udp_active" = false ]; then
			echo "local0.* @@$server:514;iris_syslog_format_v1" >> "$MNT_IRIS_UDHCP_SYSLOG_REMOTE_CONFFILE"
		else
			echo "local0.* @$server:514;iris_syslog_format_v1" >> "$MNT_IRIS_UDHCP_SYSLOG_REMOTE_CONFFILE"
		fi
	done
	# restart the service
	/etc/init.d/syslog stop 
	/etc/init.d/syslog start
fi
