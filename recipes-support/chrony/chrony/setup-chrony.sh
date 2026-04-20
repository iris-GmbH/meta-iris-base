#!/bin/sh

CFG_FILE=/mnt/iris/chrony/chrony.conf
DEFAULT_CFG=/etc/chrony.conf

reset_cfg() {
    echo 'include /etc/chrony.conf' > $CFG_FILE
    echo '# server 0.0.0.0 iburst' >> $CFG_FILE
}

# create default config if custom one does not exist
if [ ! -f $CFG_FILE ]; then
    mkdir -p /mnt/iris/chrony
    reset_cfg
fi

# reset config, if custom one does not have include yet
if ! [[ $(head -n 1 $CFG_FILE) == "include"* ]]; then
    old_server=$(grep 'server' /mnt/iris/chrony/chrony.conf | grep 'iburst')
    echo 'include /etc/chrony.conf' > $CFG_FILE
    echo $old_server >> $CFG_FILE
fi
