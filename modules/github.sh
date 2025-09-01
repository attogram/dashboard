#!/usr/bin/env bash
#
# modules/github
#
# GitHub module for the dashboard.
# Fetches repository stats for the user and repos specified in config.sh.
#
# Usage: ./modules/github <format>
#

# --- Configuration and Setup ------------------------------------------------


#echo 'github.sh started'

# Set script directory to find config.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="${SCRIPT_DIR}/../config/config.sh"

#echo "github.sh Loading config_file: $config_file"

# Load configuration
if [[ -f "$config_file" ]]; then
    # shellcheck source=../config/config.sh
    source "$config_file"
else
    echo "github.sh Error: Configuration file not found at $config_file" >&2
    exit 1
fi

# Check for required configuration
if [[ -z "$GITHUB_USER" ]]; then
    echo "github.sh Error: GITHUB_USER is not set in config.sh" >&2
    exit 1
fi
#echo "github.sh GITHUB_USER: $GITHUB_USER"

if (( ${#REPOS[@]} == 0 )); then
    # This module is optional if no repos are specified.
    # Exit gracefully without an error.
    exit 0
fi
#echo "github.sh REPOS: ${REPOS[*]}"

# --- Input ------------------------------------------------------------------

format="$1"
if [[ -z "$format" ]]; then
    echo "Usage: ${0##*/} <format>" >&2
    exit 1
fi

# --- Data Fetching and Formatting -------------------------------------------

# Function to fetch data for a single repo and return formatted string
fetch_repo_data() {
    local repo_name=$1
    local format=$2
    local api_url="https://api.github.com/repos/${GITHUB_USER}/${repo_name}"
    local api_response
    local curl_headers=()

    # Add GitHub token to headers if available
    if [[ -n "$GITHUB_TOKEN" ]]; then
        curl_headers+=(-H "Authorization: token ${GITHUB_TOKEN}")
    fi

    #echo "github.sh: repo_name: $repo_name format: $format api_url: $api_url"

    api_response=$(curl -s "${curl_headers[@]}" "$api_url")

    #echo "github.sh: api_response: $api_response"

    if (( $? != 0 )); then
        echo "Error: curl command failed for repo ${repo_name}" >&2
        return
    fi

    # Check for not found message
    if echo "$api_response" | jq -e '.message == "Not Found"' > /dev/null; then
        echo "github.sh Error: Repository '${GITHUB_USER}/${repo_name}' not found." >&2
        return
    fi

    # Check for rate limit error
    if echo "$api_response" | jq -e 'if .message then .message | contains("API rate limit exceeded") else false end' > /dev/null; then
        echo "github.sh Error: GitHub API rate limit exceeded. To avoid this, please set your GITHUB_TOKEN in the config file." >&2
        # We only want to show this error once, not for every repo.
        # A simple way to do this is to touch a temporary file.
        if [[ ! -f "/tmp/dashboard_ratelimit_error_shown" ]]; then
            touch "/tmp/dashboard_ratelimit_error_shown"
            # Clean up the temp file on exit
            trap 'rm -f /tmp/dashboard_ratelimit_error_shown' EXIT
        else
            # Error already shown, just exit silently for this repo
            return
        fi
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
            xml_repo_name=${repo_name//-/_}
            [[ $xml_repo_name =~ ^[0-9] ]] && xml_repo_name="_$xml_repo_name"
            echo "<${xml_repo_name}><stars>${stars}</stars><forks>${forks}</forks><issues>${issues}</issues><watchers>${watchers}</watchers></${xml_repo_name}>"
            ;;
        html)
            echo "<h3>${repo_name}</h3><ul><li>Stars: ${stars}</li><li>Forks: ${forks}</li><li>Open Issues: ${issues}</li><li>Watchers: ${watchers}</li></ul>"
            ;;
        yaml)
            echo "    ${repo_name}:"
            echo "      stars: ${stars}"
            echo "      forks: ${forks}"
            echo "      issues: ${issues}"
            echo "      watchers: ${watchers}"
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

github_url="https://github.com/${GITHUB_USER}"

case "$format" in
    plain)
        echo "GitHub Repositories for ${GITHUB_USER} (${github_url})"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$format"; done
        ;;
    pretty)
        echo -e "\e[1mGitHub Repositories for ${GITHUB_USER}\e[0m (${github_url})"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$format"; done
        ;;
    json)
        echo -n "\"github\":{\"user\":\"${GITHUB_USER}\",\"url\":\"${github_url}\",\"repositories\":{"
        first=true
        for repo in "${REPOS[@]}"; do
            if [[ "$first" = false ]]; then echo -n ","; fi
            fetch_repo_data "$repo" "$format"
            first=false
        done
        echo -n "}}"
        ;;
    xml)
        echo -n "<github user=\"${GITHUB_USER}\" url=\"${github_url}\">"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$format"; done
        echo -n "</github>"
        ;;
    html)
        echo -n "<h2><a href=\"${github_url}\">GitHub Repositories for ${GITHUB_USER}</a></h2>"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$format"; done
        ;;
    yaml)
        echo "github:"
        echo "  user: ${GITHUB_USER}"
        echo "  url: ${github_url}"
        echo "  repositories:"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$format"; done
        ;;
    csv)
        echo "github,user,${GITHUB_USER}"
        echo "github,url,${github_url}"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$format"; done
        ;;
    markdown)
        echo "### [GitHub Repositories for ${GITHUB_USER}](${github_url})"
        for repo in "${REPOS[@]}"; do fetch_repo_data "$repo" "$format"; done
        ;;
    *)
        echo "Error: Unsupported format '$format'" >&2
        exit 1
        ;;
esac
