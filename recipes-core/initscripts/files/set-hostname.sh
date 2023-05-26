#!/bin/sh

# filename: set-hostname

CUR_HOSTNAME="$(hostname)"
NEW_HOSTNAME=i6-"$(ip a | grep ether | head -n1 | awk '{print $2}' | tr : -)"

# Display the current hostname
echo "The current hostname is $CUR_HOSTNAME"

# Change hostname
hostname $NEW_HOSTNAME

# Display new hostname
echo "The new hostname is $NEW_HOSTNAME"
