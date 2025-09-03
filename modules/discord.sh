#!/bin/bash
#
# modules/discord.sh
#
# Discord module for the dashboard.
# Fetches online member count from a Discord server widget.
#

#echo 'modules/discord.sh started'

# --- Configuration and Setup ------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"

if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=../config.sh
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found" >&2
    exit 1
fi

if [ -z "$DISCORD_SERVER_ID" ]; then
    # This module is optional if no server ID is specified.
    exit 0
fi

# --- Input ------------------------------------------------------------------
FORMAT="$1"
if [ -z "$FORMAT" ]; then
    echo "Usage: $(basename "$0") <format>" >&2
    exit 1
fi

# --- Data Fetching ----------------------------------------------------------
API_URL="https://discord.com/api/v9/guilds/${DISCORD_SERVER_ID}/widget.json"
API_RESPONSE=$(curl -s "$API_URL")

if [ -z "$API_RESPONSE" ]; then
    echo "Error: Discord API returned an empty response." >&2
    exit 1
fi

# Check for API errors
if echo "$API_RESPONSE" | jq -e '.message' > /dev/null; then
    ERROR_MESSAGE=$(echo "$API_RESPONSE" | jq -r '.message')
    # If the widget is disabled or unavailable, it's not a fatal error for the whole report.
    # We just exit gracefully so this module doesn't produce output.
    if [[ "$ERROR_MESSAGE" == "Unknown Widget" ]] || [[ "$ERROR_MESSAGE" == "Widget Disabled" ]]; then
        exit 0
    fi
    # For other errors, print to stderr and exit
    echo "Error: Discord API returned an error - ${ERROR_MESSAGE}" >&2
    exit 1
fi

ONLINE_COUNT=$(echo "$API_RESPONSE" | jq -r '.presence_count')

if [ "$ONLINE_COUNT" == "null" ]; then
    # This can happen if the widget is disabled but doesn't return an error message
    exit 0
fi

# --- Output Formatting ------------------------------------------------------
case "$FORMAT" in
    plain)
        echo "Discord"
        echo "Online: $ONLINE_COUNT"
        ;;
    pretty)
        echo -e "\e[1mDiscord\e[0m"
        echo "Online: $ONLINE_COUNT"
        ;;
    json)
        echo "\"discord\":{\"online\":${ONLINE_COUNT}}"
        ;;
    xml)
        echo "<discord><online>${ONLINE_COUNT}</online></discord>"
        ;;
    html)
        echo "<h2>Discord</h2><ul><li>Online: ${ONLINE_COUNT}</li></ul>"
        ;;
    yaml)
        echo "discord:"
        echo "  online: ${ONLINE_COUNT}"
        ;;
    csv)
        echo "discord,online,${ONLINE_COUNT}"
        ;;
        tsv)
            now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
            printf "%s\tdiscord\tdiscord.online\t%s\n" "$now" "$ONLINE_COUNT"
            ;;
    markdown)
        echo "### Discord"
        echo "- Online: ${ONLINE_COUNT}"
        ;;
    *)
        echo "Error: Unsupported format '$FORMAT'" >&2
        exit 1
        ;;
esac
