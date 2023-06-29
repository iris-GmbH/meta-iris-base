#!/bin/sh

echo "NTP server list: $1";
ntpsrv_list=$1

echo "Reading dhcp configuration"

CUSTOMERCONFIGFILE="/etc/counter/config_customer.json"
if [ ! -f "$CUSTOMERCONFIGFILE" ]; then
    echo "$0: Can not read $CUSTOMERCONFIGFILE" 
    exit 0
fi

# Convert config to single line json so we can regex it with sed
json=$(cat "$CUSTOMERCONFIGFILE" | tr '\n' ' ')

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

echo "Configuration:"

DHCPUSEOPTION42=""

if parameterExists "pa\.communication\.dhcp_useoption42"; then                                                           
   DHCPUSEOPTION42=$(getParameter "pa\.communication\.dhcp_useoption42")                                                      
   echo " pa.communication.dhcp_useoption42:" "$DHCPUSEOPTION42"
fi

if [ "$DHCPUSEOPTION42" = true ]; then
    echo "DHCP USE OPTION 42: true - Starting ntp daemon!"
    /etc/udhcpc.d/dhcp_option_42/timeservice_dhcp_option_42.sh "$ntpsrv_list" &
    
else
    echo "DHCP USE OPTION 42: false. Nothing to do!"
fi
