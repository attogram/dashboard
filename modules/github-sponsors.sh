#!/usr/bin/env bash
#
# modules/github-sponsors
#
# GitHub Sponsors module for the dashboard.
# Fetches sponsor count for the authenticated user and outputs it in TSV format.
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
if [ -z "$GITHUB_TOKEN" ];
then
    # If no token is provided, this module is skipped.
    exit 0
fi

# --- Data Fetching ----------------------------------------------------------

GRAPHQL_QUERY="{ \\\"query\\\": \\\"query { viewer { sponsorshipsAsMaintainer(first: 1) { totalCount } } }\\\" }"
API_URL="https://api.github.com/graphql"

API_RESPONSE=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$GRAPHQL_QUERY" \
    "$API_URL")

# Check for API errors
if echo "$API_RESPONSE" | jq -e '.message' > /dev/null; then
    ERROR_MESSAGE=$(echo "$API_RESPONSE" | jq -r '.message')
    echo "Error: GitHub API returned a message - ${ERROR_MESSAGE}. Check your GITHUB_TOKEN." >&2
    exit 1
fi

if echo "$API_RESPONSE" | jq -e '.data == null' > /dev/null; then
    echo "Error: GitHub API response did not contain data. Response: $API_RESPONSE" >&2
    exit 1
fi

SPONSORS_COUNT=$(echo "$API_RESPONSE" | jq -r '.data.viewer.sponsorshipsAsMaintainer.totalCount')

if [ "$SPONSORS_COUNT" == "null" ]; then
    echo "Error: Could not retrieve sponsor count." >&2
    exit 1
fi

# --- Output Formatting ------------------------------------------------------

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf "%s\tgithub-sponsors\tsponsors\tgithub-sponsors\t%s\n" "$now" "$SPONSORS_COUNT"
