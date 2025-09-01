#!/usr/bin/env bash
#
# modules/github-sponsors
#
# GitHub Sponsors module for the dashboard.
# Fetches sponsor count for the authenticated user.
#
# Usage: ./modules/github-sponsors <format>
#

#echo 'modules/github-sponsors.sh started'

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
if [[ -z "$GITHUB_TOKEN" ]];
then
    # If no token is provided, this module is skipped.
    exit 0
fi

# --- Input ------------------------------------------------------------------

format="$1"
if [[ -z "$format" ]]; then
    echo "Usage: ${0##*/} <format>" >&2
    exit 1
fi

# --- Data Fetching ----------------------------------------------------------

graphql_query="{ \\\"query\\\": \\\"query { viewer { sponsorshipsAsMaintainer(first: 1) { totalCount } } }\\\" }"
api_url="https://api.github.com/graphql"

api_response=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$graphql_query" \
    "$api_url")

# Check for API errors
if echo "$api_response" | jq -e '.message' > /dev/null; then
    error_message=$(echo "$api_response" | jq -r '.message')
    if [[ "$error_message" == *"API rate limit exceeded"* ]]; then
        echo "Error: GitHub API rate limit exceeded. This module requires a GITHUB_TOKEN with the 'read:user' scope." >&2
    elif [[ "$error_message" == *"Bad credentials"* ]]; then
        echo "Error: GitHub API returned 'Bad credentials'. Please check your GITHUB_TOKEN." >&2
    else
        echo "Error: GitHub API returned a message - ${error_message}. Check your GITHUB_TOKEN." >&2
    fi
    exit 1
fi

if echo "$api_response" | jq -e '.data == null' > /dev/null; then
    echo "Error: GitHub API response did not contain data. Response: $api_response" >&2
    exit 1
fi

sponsors_count=$(echo "$api_response" | jq -r '.data.viewer.sponsorshipsAsMaintainer.totalCount')

if [[ "$sponsors_count" == "null" ]]; then
    echo "Error: Could not retrieve sponsor count." >&2
    exit 1
fi

# --- Output Formatting ------------------------------------------------------

if [[ -z "$GITHUB_USER" ]]; then
    # Fallback if GITHUB_USER is not set, though it should be.
    sponsors_url="https://github.com/sponsors"
    sponsors_title="GitHub Sponsors"
else
    sponsors_url="https://github.com/sponsors/${GITHUB_USER}"
    sponsors_title="GitHub Sponsors for ${GITHUB_USER}"
fi


case "$format" in
    plain)
        echo "${sponsors_title} (${sponsors_url})"
        echo "Sponsors: $sponsors_count"
        ;;
    pretty)
        echo -e "\e[1m${sponsors_title}\e[0m (${sponsors_url})"
        echo "Sponsors: $sponsors_count"
        ;;
    json)
        echo "\"github-sponsors\":{\"user\":\"${GITHUB_USER}\",\"url\":\"${sponsors_url}\",\"sponsors\":${sponsors_count}}"
        ;;
    xml)
        echo "<github_sponsors user=\"${GITHUB_USER}\" url=\"${sponsors_url}\"><sponsors>${sponsors_count}</sponsors></github_sponsors>"
        ;;
    html)
        echo "<h2><a href=\"${sponsors_url}\">${sponsors_title}</a></h2><ul><li>Sponsors: ${sponsors_count}</li></ul>"
        ;;
    yaml)
        echo "github-sponsors:"
        echo "  user: ${GITHUB_USER}"
        echo "  url: ${sponsors_url}"
        echo "  sponsors: ${sponsors_count}"
        ;;
    csv)
        echo "github-sponsors,user,${GITHUB_USER}"
        echo "github-sponsors,url,${sponsors_url}"
        echo "github-sponsors,sponsors,${sponsors_count}"
        ;;
    markdown)
        echo "### [${sponsors_title}](${sponsors_url})"
        echo "- Sponsors: ${sponsors_count}"
        ;;
    *)
        echo "Error: Unsupported format '$format'" >&2
        exit 1
        ;;
esac
