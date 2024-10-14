#!/bin/bash

# Function to add a timestamp to echo
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Path to the .env file and random.sh script
ENV_FILE=".env"
RANDOM_SCRIPT="./random.sh"

# Get the current IP from ifconfig.co
current_ip=$(curl -m 5 -s ifconfig.co)

# Extract the public IP from the .env file
stored_ip=$(grep 'PUBLIC_IP' "$ENV_FILE" | cut -d '=' -f2)

# Compare the current IP with the stored IP
if [ "$current_ip" != "$stored_ip" ]; then
    log "Public IP has changed from $stored_ip to $current_ip."

    # Update the .env file with the new IP
    sed -i "s/PUBLIC_IP=.*/PUBLIC_IP=$current_ip/" "$ENV_FILE"
    log ".env file updated with new IP."

    # Run the random.sh script
    log "Running random.sh due to IP change..."
    "$RANDOM_SCRIPT"

    # Exit with code 0 indicating the IP has changed
    exit 0
else
    log "Public IP has not changed. Current IP: $current_ip."

    # Exit with code 1 indicating no change
    exit 1
fi
