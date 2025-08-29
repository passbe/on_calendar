#!/bin/bash

# Simple helper to take expression input and use systemd-analyze to get fixture format
# Usage: fixture-helper.sh [expression] >> ./test/fixtures/expressions.yaml
# Note: This is rough and ready! HARDCODED UTC!

# Generate random clamp value
start_date="1970-01-01 00:00:00"
end_date="2200-12-31 23:59:59"
start_timestamp=$(date -d "$start_date" +%s)
end_timestamp=$(date -d "$end_date" +%s)
duration_seconds=$((end_timestamp - start_timestamp))
random_offset_seconds=$(shuf -i 0-$duration_seconds -n 1)
random_timestamp=$((start_timestamp + random_offset_seconds))
clamp=$(date -d "@$random_timestamp" +"%Y-%m-%d %H:%M:%S +0000")

# Get output of systemd-analyze
output=$(/usr/bin/systemd-analyze calendar --iterations=4 --base-time="$clamp" "$1 UTC" | grep "in UTC" | awk -F' ' '{print $4,$5}')

cat << EOF
  - expression: "$1"
    clamp: $clamp
    iterations:
EOF
while IFS= read -r line; do
	echo "      - $line +0000"
done <<< "$output"
