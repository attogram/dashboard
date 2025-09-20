#!/usr/bin/env bash
#
# modules/github
#
# GitHub module for the dashboard.
# Fetches repository stats for the user and repos specified in config.sh
# and outputs them in TSV format.
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
    echo "github.sh Error: Configuration file not found at $CONFIG_FILE" >&2
    exit 1
fi

# Check for required configuration
if [ -z "$GITHUB_USER" ]; then
    echo "github.sh Error: GITHUB_USER is not set in config.sh" >&2
    exit 1
fi

if [ ${#REPOS[@]} -eq 0 ]; then
    # This module is optional if no repos are specified.
    # Exit gracefully without an error.
    exit 0
fi

# --- Data Fetching and Formatting -------------------------------------------

# Helper function to safely get a value from jq
get_json_value() {
    local json=$1
    local key=$2
    local value
    value=$(echo "$json" | jq -r "$key")
    if [ "$value" == "null" ] || [ -z "$value" ]; then
        echo "0"
    else
        echo "$value"
    fi
}

fetch_repo_data() {
    local repo_name=$1
    local api_url="https://api.github.com/repos/${GITHUB_USER}/${repo_name}"
    local api_response
    local curl_headers=()

    # Add GitHub token to headers if available
    if [ -n "$GITHUB_TOKEN" ]; then
        curl_headers+=(-H "Authorization: token ${GITHUB_TOKEN}")
    fi

    api_response=$(curl -s "${curl_headers[@]}" "$api_url")

    if [ $? -ne 0 ]; then
        echo "Error: curl command failed for repo ${repo_name}" >&2
        return
    fi

    # Check for not found message
    if echo "$api_response" | jq -e '.message == "Not Found"' > /dev/null; then
        echo "github.sh Error: Repository '${GITHUB_USER}/${repo_name}' not found." >&2
        return
    fi

    local stars
    local forks
    local issues
    local watchers
    local open_prs
    local closed_prs

    stars=$(get_json_value "$api_response" '.stargazers_count')
    forks=$(get_json_value "$api_response" '.forks_count')
    issues=$(get_json_value "$api_response" '.open_issues_count')
    watchers=$(get_json_value "$api_response" '.subscribers_count')

    # Fetch PR counts using the search API to be more efficient
    local search_api_url="https://api.github.com/search/issues?q=is:pr+repo:${GITHUB_USER}/${repo_name}"
    local open_prs_response
    local closed_prs_response
    open_prs_response=$(curl -s "${curl_headers[@]}" "${search_api_url}+is:open")
    closed_prs_response=$(curl -s "${curl_headers[@]}" "${search_api_url}+is:closed")

    open_prs=$(get_json_value "$open_prs_response" '.total_count')
    closed_prs=$(get_json_value "$closed_prs_response" '.total_count')

    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    printf "%s\tgithub\tstars\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$stars"
    printf "%s\tgithub\tforks\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$forks"
    printf "%s\tgithub\topen_issues\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$issues"
    printf "%s\tgithub\twatchers\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$watchers"
    printf "%s\tgithub\topen_prs\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$open_prs"
    printf "%s\tgithub\tclosed_prs\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$closed_prs"
}

# --- Main Output Generation -------------------------------------------------

for repo in "${REPOS[@]}"; do
    fetch_repo_data "$repo"
done
