#!/bin/bash

# Function to add a timestamp to echo
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Path to the JSON file
JSON_FILE="wkeys.json"

# Check if jq is installed (for parsing JSON)
if ! command -v jq &> /dev/null
then
    echo "jq is required but it's not installed. Install it first."
    exit 1
fi

# Get the total number of regions in the JSON file
REGION_COUNT=$(jq '.proton | length' "$JSON_FILE")

# Select a random index between 0 and REGION_COUNT-1
RANDOM_INDEX=$((RANDOM % REGION_COUNT))

# Get the region at the random index
RANDOM_REGION=$(jq -r ".proton[$RANDOM_INDEX].region" "$JSON_FILE")

# Invoke the reload script with the randomly selected region
log "Randomly selected region: $RANDOM_REGION"
sudo ./reload.sh "$RANDOM_REGION"
