#!/usr/bin/env bash
#
# modules/discord.sh
#
# Discord module for the dashboard.
# Fetches online member count from a Discord server widget.
#

#echo 'modules/discord.sh started'

# --- Configuration and Setup ------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="${SCRIPT_DIR}/../config/config.sh"

if [[ -f "$config_file" ]]; then
    # shellcheck source=../config/config.sh
    source "$config_file"
else
    echo "Error: Configuration file not found" >&2
    exit 1
fi

if [[ -z "$DISCORD_SERVER_ID" ]]; then
    # This module is optional if no server ID is specified.
    exit 0
fi

# --- Input ------------------------------------------------------------------
format="$1"
if [[ -z "$format" ]]; then
    echo "Usage: ${0##*/} <format>" >&2
    exit 1
fi

# --- Data Fetching ----------------------------------------------------------
api_url="https://discord.com/api/v9/guilds/${DISCORD_SERVER_ID}/widget.json"
api_response=$(curl -s "$api_url")

if [[ -z "$api_response" ]]; then
    echo "Error: Discord API returned an empty response." >&2
    exit 1
fi

# Check for API errors
if echo "$api_response" | jq -e '.message' > /dev/null; then
    error_message=$(echo "$api_response" | jq -r '.message')
    # If the widget is disabled or unavailable, it's not a fatal error for the whole report.
    # We just exit gracefully so this module doesn't produce output.
    if [[ "$error_message" == "Unknown Widget" || "$error_message" == "Widget Disabled" ]]; then
        exit 0
    fi
    # For other errors, print to stderr and exit
    echo "Error: Discord API returned an error - ${error_message}" >&2
    exit 1
fi

online_count=$(echo "$api_response" | jq -r '.presence_count')
server_name=$(echo "$api_response" | jq -r '.name')

if [[ "$online_count" == "null" ]]; then
    # This can happen if the widget is disabled but doesn't return an error message
    exit 0
fi

# --- Output Formatting ------------------------------------------------------
case "$format" in
    plain)
        echo "Discord Server: ${server_name} (${DISCORD_SERVER_ID})"
        echo "Online: $online_count"
        ;;
    pretty)
        echo -e "\e[1mDiscord Server: ${server_name}\e[0m (${DISCORD_SERVER_ID})"
        echo "Online: $online_count"
        ;;
    json)
        echo "\"discord\":{\"server_name\":\"${server_name}\",\"server_id\":\"${DISCORD_SERVER_ID}\",\"online\":${online_count}}"
        ;;
    xml)
        echo "<discord server_name=\"${server_name}\" server_id=\"${DISCORD_SERVER_ID}\"><online>${online_count}</online></discord>"
        ;;
    html)
        echo "<h2>Discord Server: ${server_name}</h2><ul><li>ID: ${DISCORD_SERVER_ID}</li><li>Online: ${online_count}</li></ul>"
        ;;
    yaml)
        echo "discord:"
        echo "  server_name: \"${server_name}\""
        echo "  server_id: \"${DISCORD_SERVER_ID}\""
        echo "  online: ${online_count}"
        ;;
    csv)
        echo "discord,server_name,${server_name}"
        echo "discord,server_id,${DISCORD_SERVER_ID}"
        echo "discord,online,${online_count}"
        ;;
    markdown)
        echo "### Discord Server: ${server_name}"
        echo "- ID: ${DISCORD_SERVER_ID}"
        echo "- Online: ${online_count}"
        ;;
    *)
        echo "Error: Unsupported format '$format'" >&2
        exit 1
        ;;
esac
