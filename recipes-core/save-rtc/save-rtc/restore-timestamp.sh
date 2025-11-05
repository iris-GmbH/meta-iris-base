#!/bin/sh

TIMESTAMP_FILE=/mnt/iris/timestamp
DEFAULT_TIMESTAMP_FILE=/etc/timestamp

# Read saved timestamp, use default none is present
if [ ! -f "$TIMESTAMP_FILE" ]; then
    cp "$DEFAULT_TIMESTAMP_FILE" "$TIMESTAMP_FILE"
fi

SAVED_TIME=$(cat "$TIMESTAMP_FILE")

# Format: YYYYMMDDHHmmSS
YEAR=$(echo "$SAVED_TIME" | cut -c1-4)
MONTH=$(echo "$SAVED_TIME" | cut -c5-6)
DAY=$(echo "$SAVED_TIME" | cut -c7-8)
HOUR=$(echo "$SAVED_TIME" | cut -c9-10)
MINUTE=$(echo "$SAVED_TIME" | cut -c11-12)
SECOND=$(echo "$SAVED_TIME" | cut -c13-14)

# Convert saved timestamp to seconds since epoch
SAVED_EPOCH=$(date -d "$YEAR$MONTH$DAY $HOUR:$MINUTE:$SECOND" +%s 2>/dev/null)

# Get current system time in seconds since epoch
CURRENT_EPOCH=$(date +%s)

# If saved time is greater than current time, restore it
if [ "$SAVED_EPOCH" -gt "$CURRENT_EPOCH" ]; then
    echo "Restoring time from $TIMESTAMP_FILE (saved: $SAVED_TIME, current system time is older)"
    # Format: YYYY-MM-DD HH:MM:SS
    FORMATTED_TIME="$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND"
    timedatectl set-time "$FORMATTED_TIME" # timedatectl also sets the rtc
else
    echo "System time is newer than saved timestamp, not restoring"
fi
