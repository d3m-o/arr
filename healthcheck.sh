#!/bin/bash

# Function to add a timestamp to echo
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Step 1: Check the time and skip checks between 4:00 and 4:30 AM
current_hour=$(date +"%H")
current_minute=$(date +"%M")
if [[ "$current_hour" -eq 4 && "$current_minute" -lt 30 ]]; then
    log "Skipping checks between 4:00 AM and 4:30 AM."
    exit 0
fi

# Path to ipcheck.sh and random.sh scripts
IPCHECK_SCRIPT="./ipcheck.sh"
RANDOM_SCRIPT="./random.sh"

# Step 2: Run ipcheck.sh and check if the IP has changed
$IPCHECK_SCRIPT
if [ $? -eq 0 ]; then
    log "Public IP has changed, exiting health check."
    exit 0
fi

# Get the current minute
current_minute=$(date +"%M")

# Run the speed test if the current time is between 43 and 48 minutes
if [ "$current_minute" -ge 43 ] && [ "$current_minute" -le 48 ]; then
    # Path to speedcheck.sh
    SPEEDCHECK_SCRIPT="./speedcheck.sh"

    # Step 3: Run speedcheck.sh and see if the VPN connection speed has degraded to an unsuitable threshold
    $SPEEDCHECK_SCRIPT
    if [ $? -eq 0 ]; then
        log "Restarted containers due to degraded speed, exiting health check."
        exit 0
    fi
else
    log "Skipping speed test, only runs at 45 past the hour."
fi

# Containers to check
containers=("flaresolverr" "gluetun" "prowlarr" "radarr" "sonarr" "speedtest-tracker" "qbittorrent")

# Flag to track unhealthy or stopped containers
unhealthy_found=false

# Step 4: Loop through each container and check its state
for container in "${containers[@]}"; do
    log "Checking container: $container"

    # Inspect the container to get its state
    state=$(sudo docker inspect --format '{{json .State}}' "$container")

    # Check if the container is running
    is_running=$(echo "$state" | jq -r '.Running')
    if [ "$is_running" != "true" ]; then
        log "Container $container is not running!"
        unhealthy_found=true
        continue
    fi

    # Check if the container has a Health object and its status
    has_health=$(echo "$state" | jq -r 'has("Health")')
    if [ "$has_health" == "true" ]; then
        health_status=$(echo "$state" | jq -r '.Health.Status')
        if [ "$health_status" != "healthy" ]; then
            log "Container $container is not healthy! Status: $health_status"
            unhealthy_found=true
        fi
    else
        log "Container $container is running, no health check available."
    fi
done

# Step 5: If any unhealthy container is found, run random.sh
if [ "$unhealthy_found" = true ]; then
    log "At least one container is unhealthy or not running. Running random.sh..."
    "$RANDOM_SCRIPT"
else
    log "All specified containers are running and healthy."
fi
