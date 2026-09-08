#!/bin/sh
TIMESTAMP_FILE="/mnt/iris/timestamp"

ERROR=$(date -u +%4Y%2m%2d%2H%2M%2S 2>&1 > "$TIMESTAMP_FILE")
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
    echo "Failed to save timestamp (exit status $STATUS): $ERROR" >&2
fi

exit "$STATUS"
