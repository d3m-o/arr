#!/bin/bash

# Path to the JSON file
JSON_FILE="wkeys.json"

# Path to the .env file
ENV_FILE=".env"

# Check if jq is installed (for parsing JSON)
if ! command -v jq &> /dev/null
then
    echo "jq is required but it's not installed. Install it first."
    exit 1
fi

# Function to list available regions
list_regions() {
    echo "Available regions:"
    jq -r '.proton[] | .region' "$JSON_FILE"
}

# Function to update the .env file with the selected region and key
update_env_file() {
    REGION=$1
    # Get the key for the specified region
    KEY=$(jq -r --arg REGION "$REGION" '.proton[] | select(.region == $REGION) | .key' "$JSON_FILE")

    if [ -z "$KEY" ]; then
        echo "Region not found: $REGION"
        exit 1
    fi

    # Update the .env file
    echo "Updating .env file with region $REGION and key..."
    sed -i "s|WIREGUARD_PRIVATE_KEY=.*|WIREGUARD_PRIVATE_KEY=$KEY #$REGION|" "$ENV_FILE"
}

# Main logic
if [ -z "$1" ]; then
    # If no argument is passed, list available regions
    list_regions
else
    # If a region is specified, update the .env file and restart the stack
    update_env_file "$1"

    # Restart the Docker stack
    echo "Restarting Docker stack..."
    sudo docker compose down
    sudo docker compose up -d
    echo "Docker stack restarted with region $1."
fi
