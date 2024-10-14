#!/bin/bash

# Function to add a timestamp to echo
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Path to the random.sh script
RANDOM_SCRIPT="./random.sh"

# Run the speedtest inside the speedtest-tracker Docker container and capture the output
speedtest_output=$(sudo docker exec speedtest-tracker speedtest)

# Extract the download speed from the speedtest output
download_speed=$(echo "$speedtest_output" | grep -oP '(?<=Download:\s{3})[0-9.]+')

# Echo the result
log "Latest speedtest result: $download_speed Mbps"

# Check if the download speed is less than 100 Mbps
if (( $(echo "$download_speed < 100" | bc -l) )); then
    log "Speed is below 100 Mbps, running random.sh..."
    "$RANDOM_SCRIPT"

    # Exit 0 if the containers were restarted
    exit 0
else
    log "Speed is above 100 Mbps, no action taken."

    # Exit 1 if the speed is ok
    exit 1
fi
