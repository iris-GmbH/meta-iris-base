#!/bin/sh
TIMESTAMP_FILE="/mnt/iris/timestamp"
date -u +%4Y%2m%2d%2H%2M%2S 2>/dev/null > "$TIMESTAMP_FILE"
