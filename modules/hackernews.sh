#!/bin/bash
#
# modules/hackernews
#
# Hacker News module for the dashboard.
# Fetches karma for the user specified in config.sh.
#
# Usage: ./modules/hackernews <format>
#

#echo 'modules/hackernews.sh started'

# --- Configuration and Setup ------------------------------------------------

# Set script directory to find config.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.sh"

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
    echo "Error: HN_USER is not set in config.sh" >&2
    exit 1
fi

# --- Input ------------------------------------------------------------------

FORMAT="$1"
if [ -z "$FORMAT" ]; then
    echo "Usage: $(basename "$0") <format>" >&2
    exit 1
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

case "$FORMAT" in
    plain)
        echo "Hacker News"
        echo "Karma: $KARMA"
        ;;
    pretty)
        echo -e "\e[1mHacker News\e[0m"
        echo "Karma: $KARMA"
        ;;
    json)
        echo "\"hackernews\":{\"karma\":${KARMA}}"
        ;;
    xml)
        echo "<hackernews><karma>${KARMA}</karma></hackernews>"
        ;;
    html)
        echo "<h2>Hacker News</h2><ul><li>Karma: ${KARMA}</li></ul>"
        ;;
    yaml)
        echo "hackernews:"
        echo "  karma: ${KARMA}"
        ;;
    csv)
        echo "hackernews,karma,${KARMA}"
        ;;
    markdown)
        echo "### Hacker News"
        echo "- Karma: ${KARMA}"
        ;;
    *)
        echo "Error: Unsupported format '$FORMAT'" >&2
        exit 1
        ;;
esac
