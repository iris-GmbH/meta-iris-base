#Switch to real root
echo "Switch to root"
exec switch_root ${ROOT_MNT} ${INIT} ${CMDLINE}
