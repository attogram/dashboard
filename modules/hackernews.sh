#!/usr/bin/env bash
#
# modules/hackernews
#
# Hacker News module for the dashboard.
# Fetches karma for the user specified in config.sh and outputs it in TSV format.
#

# --- Configuration and Setup ------------------------------------------------

# Set script directory to find config.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=../config.sh
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found at $CONFIG_FILE" >&2
    exit 1
fi

# Check for required configuration
if [ -z "$HN_USER" ]; then
    # This module is optional if HN_USER is not set.
    # Exit gracefully without an error.
    exit 0
fi

# --- Data Fetching ----------------------------------------------------------

API_URL="https://hacker-news.firebaseio.com/v0/user/${HN_USER}.json"
API_RESPONSE=$(curl -s "$API_URL")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: curl command failed to fetch data from $API_URL" >&2
    exit 1
fi

# Check for empty response
if [ -z "$API_RESPONSE" ] || [ "$API_RESPONSE" == "null" ]; then
    echo "Error: No data received for user '$HN_USER'. Please check the username." >&2
    exit 1
fi

KARMA=$(echo "$API_RESPONSE" | jq -r '.karma')

# --- Output Formatting ------------------------------------------------------

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf "%s\thackernews\tkarma\t%s\t%s\n" "$now" "$HN_USER" "$KARMA"
