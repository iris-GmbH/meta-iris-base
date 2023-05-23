#!/bin/sh

echo "NTP server list: $1";
ntpsrv_list=$1

#Unterscheidung ob es R1 oder R2 ist

#if IRMA6_RELEASE==1
    ./starting_busybox_ntpdaemon.sh $ntpsrv_list
    
#elif IRMA6_RELEASE==2
	./starting_chrony_ntpdaemon.sh $ntpsrv_list

#endif
