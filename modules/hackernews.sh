#!/usr/bin/env bash
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
config_file="${SCRIPT_DIR}/../config/config.sh"

# Load configuration
if [[ -f "$config_file" ]]; then
    # shellcheck source=../config/config.sh
    source "$config_file"
else
    echo "Error: Configuration file not found at $config_file" >&2
    exit 1
fi

# Check for required configuration
if [[ -z "$HN_USER" ]]; then
    echo "Error: HN_USER is not set in config.sh" >&2
    exit 1
fi

# --- Input ------------------------------------------------------------------

format="$1"
if [[ -z "$format" ]]; then
    echo "Usage: ${0##*/} <format>" >&2
    exit 1
fi

# --- Data Fetching ----------------------------------------------------------

api_url="https://hacker-news.firebaseio.com/v0/user/${HN_USER}.json"
api_response=$(curl -s "$api_url")

# Check if curl command was successful
if (( $? != 0 )); then
    echo "Error: curl command failed to fetch data from $api_url" >&2
    exit 1
fi

# Check for empty response
if [[ -z "$api_response" || "$api_response" == "null" ]]; then
    echo "Error: No data received for user '$HN_USER'. Please check the username." >&2
    exit 1
fi

karma=$(echo "$api_response" | jq -r '.karma')

# --- Output Formatting ------------------------------------------------------

hn_url="https://news.ycombinator.com/user?id=${HN_USER}"

case "$format" in
    plain)
        echo "Hacker News for ${HN_USER} (${hn_url})"
        echo "Karma: $karma"
        ;;
    pretty)
        echo -e "\e[1mHacker News for ${HN_USER}\e[0m (${hn_url})"
        echo "Karma: $karma"
        ;;
    json)
        echo "\"hackernews\":{\"user\":\"${HN_USER}\",\"url\":\"${hn_url}\",\"karma\":${karma}}"
        ;;
    xml)
        echo "<hackernews user=\"${HN_USER}\" url=\"${hn_url}\"><karma>${karma}</karma></hackernews>"
        ;;
    html)
        echo "<h2><a href=\"${hn_url}\">Hacker News for ${HN_USER}</a></h2><ul><li>Karma: ${karma}</li></ul>"
        ;;
    yaml)
        echo "hackernews:"
        echo "  user: ${HN_USER}"
        echo "  url: ${hn_url}"
        echo "  karma: ${karma}"
        ;;
    csv)
        echo "hackernews,user,${HN_USER}"
        echo "hackernews,url,${hn_url}"
        echo "hackernews,karma,${karma}"
        ;;
    markdown)
        echo "### [Hacker News for ${HN_USER}](${hn_url})"
        echo "- Karma: ${karma}"
        ;;
    *)
        echo "Error: Unsupported format '$format'" >&2
        exit 1
        ;;
esac
