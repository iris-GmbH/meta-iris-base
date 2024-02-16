#!/bin/sh

# SWUpdate is configured with /etc/swupdate.cfg. The webserver must be
# enabled via argument even if it is not configured here!
exec /usr/bin/swupdate -w ''
