#!/bin/bash

# Function to add a timestamp to echo
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Path to the SQLite database
DB_PATH="/docker/appdata/speedtest/database.sqlite"

# Check if the user provided an argument for the number of days
if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_days>"
    exit 1
fi

# Get the number of days from the argument
DAYS=$1

# Get the date 'x' days ago
threshold_date=$(date -d "$DAYS days ago" '+%Y-%m-%d')

# Count how many rows will be deleted
rows_to_delete=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM results WHERE date(created_at) < date('$threshold_date');")

if [ "$rows_to_delete" -gt 0 ]; then
    # Run the SQLite query to delete old records
    sqlite3 "$DB_PATH" "DELETE FROM results WHERE date(created_at) < date('$threshold_date');"
    log "Deleted $rows_to_delete entries older than $DAYS days from the results table."
else
    log "No entries older than $DAYS days to delete."
fi
