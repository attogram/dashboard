#!/bin/bash
#
# modules/github
#
# GitHub module for the dashboard.
# Fetches repository stats for the user and repos specified in config.sh.
#
# Usage: ./modules/github <format>
#

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
if [ -z "$GITHUB_USER" ]; then
    echo "Error: GITHUB_USER is not set in config.sh" >&2
    exit 1
fi
if [ ${#REPOS[@]} -eq 0 ]; then
    # This module is optional if no repos are specified.
    # Exit gracefully without an error.
    exit 0
fi

# --- Input ------------------------------------------------------------------

FORMAT="$1"
if [ -z "$FORMAT" ]; then
    echo "Usage: $(basename "$0") <format>" >&2
    exit 1
fi

# --- Data Fetching and Formatting -------------------------------------------

# Function to fetch data for a single repo and return formatted string
fetch_repo_data() {
    local repo_name=$1
    local format=$2
    local api_url="https://api.github.com/repos/${GITHUB_USER}/${repo_name}"
    local api_response

    api_response=$(curl -s "$api_url")

    if [ $? -ne 0 ]; then
        echo "Error: curl command failed for repo ${repo_name}" >&2
        return
    fi

    # Check for not found message
    if echo "$api_response" | jq -e '.message == "Not Found"' > /dev/null; then
        echo "Error: Repository '${GITHUB_USER}/${repo_name}' not found." >&2
        return
    fi

    local stars
    local forks
    local issues
    local watchers

    stars=$(echo "$api_response" | jq -r '.stargazers_count')
    forks=$(echo "$api_response" | jq -r '.forks_count')
    issues=$(echo "$api_response" | jq -r '.open_issues_count')
    watchers=$(echo "$api_response" | jq -r '.subscribers_count')

    case "$format" in
        plain)
            echo "  ${repo_name}:"
            echo "    Stars: ${stars}"
            echo "    Forks: ${forks}"
            echo "    Open Issues: ${issues}"
            echo "    Watchers: ${watchers}"
            ;;
        pretty)
            echo -e "  \e[1m${repo_name}\e[0m:"
            echo "    Stars: ${stars}"
            echo "    Forks: ${forks}"
            echo "    Open Issues: ${issues}"
            echo "    Watchers: ${watchers}"
            ;;
        json)
            echo "\"${repo_name}\":{\"stars\":${stars},\"forks\":${forks},\"issues\":${issues},\"watchers\":${watchers}}"
            ;;
        xml)
            echo "<${repo_name}><stars>${stars}</stars><forks>${forks}</forks><issues>${issues}</issues><watchers>${watchers}</watchers></${repo_name}>"
            ;;
        html)
            echo "<h3>${repo_name}</h3><ul><li>Stars: ${stars}</li><li>Forks: ${forks}</li><li>Open Issues: ${issues}</li><li>Watchers: ${watchers}</li></ul>"
            ;;
        yaml)
            echo "  ${repo_name}:"
            echo "    stars: ${stars}"
            echo "    forks: ${forks}"
            echo "    issues: ${issues}"
            echo "    watchers: ${watchers}"
            ;;
        csv)
            echo "github,${repo_name},stars,${stars}"
            echo "github,${repo_name},forks,${forks}"
            echo "github,${repo_name},issues,${issues}"
            echo "github,${repo_name},watchers,${watchers}"
            ;;
        markdown)
            echo "#### ${repo_name}"
            echo "- Stars: ${stars}"
            echo "- Forks: ${forks}"
            echo "- Open Issues: ${issues}"
            echo "- Watchers: ${watchers}"
            ;;
    esac
}

# --- Main Output Generation -------------------------------------------------

case "$FORMAT" in
    plain)
        echo "GitHub Repositories"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$FORMAT"; done
        ;;
    pretty)
        echo -e "\e[1mGitHub Repositories\e[0m"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$FORMAT"; done
        ;;
    json)
        echo -n "\"github\":{"
        first=true
        for repo in "${REPOS[@]}"; do
            if [ "$first" = false ]; then echo -n ","; fi
            fetch_repo_data "$repo" "$FORMAT"
            first=false
        done
        echo -n "}"
        ;;
    xml)
        echo -n "<github>"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$FORMAT"; done
        echo -n "</github>"
        ;;
    html)
        echo -n "<h2>GitHub Repositories</h2>"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$FORMAT"; done
        ;;
    yaml)
        echo "github:"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$FORMAT"; done
        ;;
    csv)
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$FORMAT"; done
        ;;
    markdown)
        echo "### GitHub Repositories"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$FORMAT"; done
        ;;
    *)
        echo "Error: Unsupported format '$FORMAT'" >&2
        exit 1
        ;;
esac
