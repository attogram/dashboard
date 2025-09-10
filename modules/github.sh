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
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"

#echo "github.sh Loading CONFIG_FILE: $CONFIG_FILE"

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
#echo "github.sh GITHUB_USER: $GITHUB_USER"

if [ ${#REPOS[@]} -eq 0 ]; then
    # This module is optional if no repos are specified.
    # Exit gracefully without an error.
    exit 0
fi
#echo "github.sh REPOS: ${REPOS[*]}"

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
    local curl_headers=()

    # Add GitHub token to headers if available
    if [ -n "$GITHUB_TOKEN" ]; then
        curl_headers+=(-H "Authorization: token ${GITHUB_TOKEN}")
    fi

    #echo "github.sh: repo_name: $repo_name format: $format api_url: $api_url"

    api_response=$(curl -s "${curl_headers[@]}" "$api_url")

    #echo "github.sh: api_response: $api_response"

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

    stars=$(echo "$api_response" | jq -r '.stargazers_count')
    forks=$(echo "$api_response" | jq -r '.forks_count')
    issues=$(echo "$api_response" | jq -r '.open_issues_count')
    watchers=$(echo "$api_response" | jq -r '.subscribers_count')

    # Fetch PR counts using the search API to be more efficient
    local search_api_url="https://api.github.com/search/issues?q=is:pr+repo:${GITHUB_USER}/${repo_name}"
    open_prs=$(curl -s "${curl_headers[@]}" "${search_api_url}+is:open" | jq -r '.total_count')
    closed_prs=$(curl -s "${curl_headers[@]}" "${search_api_url}+is:closed" | jq -r '.total_count')


    case "$format" in
        plain)
            echo "  ${repo_name}:"
            echo "    Stars: ${stars}"
            echo "    Forks: ${forks}"
            echo "    Open Issues: ${issues}"
            echo "    Watchers: ${watchers}"
            echo "    Open PRs: ${open_prs}"
            echo "    Closed PRs: ${closed_prs}"
            ;;
        pretty)
            echo -e "  \e[1m${repo_name}\e[0m:"
            echo "    Stars: ${stars}"
            echo "    Forks: ${forks}"
            echo "    Open Issues: ${issues}"
            echo "    Watchers: ${watchers}"
            echo "    Open PRs: ${open_prs}"
            echo "    Closed PRs: ${closed_prs}"
            ;;
        json)
            echo "\"${repo_name}\":{\"stars\":${stars},\"forks\":${forks},\"issues\":${issues},\"watchers\":${watchers},\"open_prs\":${open_prs},\"closed_prs\":${closed_prs}}"
            ;;
        xml)
            xml_repo_name=$(echo "$repo_name" | sed 's/-/_/g' | sed 's/^[0-9]/_&/')
            echo "<${xml_repo_name}><stars>${stars}</stars><forks>${forks}</forks><issues>${issues}</issues><watchers>${watchers}</watchers><open_prs>${open_prs}</open_prs><closed_prs>${closed_prs}</closed_prs></${xml_repo_name}>"
            ;;
        html)
            echo "<h3>${repo_name}</h3><ul><li>Stars: ${stars}</li><li>Forks: ${forks}</li><li>Open Issues: ${issues}</li><li>Watchers: ${watchers}</li><li>Open PRs: ${open_prs}</li><li>Closed PRs: ${closed_prs}</li></ul>"
            ;;
        yaml)
            echo "  ${repo_name}:"
            echo "    stars: ${stars}"
            echo "    forks: ${forks}"
            echo "    issues: ${issues}"
            echo "    watchers: ${watchers}"
            echo "    open_prs: ${open_prs}"
            echo "    closed_prs: ${closed_prs}"
            ;;
        csv)
            now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
            printf "%s,github,stars,repo.%s.%s,%s\n" "$now" "$GITHUB_USER" "$repo_name" "$stars"
            printf "%s,github,forks,repo.%s.%s,%s\n" "$now" "$GITHUB_USER" "$repo_name" "$forks"
            printf "%s,github,open_issues,repo.%s.%s,%s\n" "$now" "$GITHUB_USER" "$repo_name" "$issues"
            printf "%s,github,watchers,repo.%s.%s,%s\n" "$now" "$GITHUB_USER" "$repo_name" "$watchers"
            printf "%s,github,open_prs,repo.%s.%s,%s\n" "$now" "$GITHUB_USER" "$repo_name" "$open_prs"
            printf "%s,github,closed_prs,repo.%s.%s,%s\n" "$now" "$GITHUB_USER" "$repo_name" "$closed_prs"
            ;;
        tsv)
            local now
            now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
            printf "%s\tgithub\tstars\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$stars"
            printf "%s\tgithub\tforks\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$forks"
            printf "%s\tgithub\topen_issues\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$issues"
            printf "%s\tgithub\twatchers\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$watchers"
            printf "%s\tgithub\topen_prs\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$open_prs"
            printf "%s\tgithub\tclosed_prs\trepo.%s.%s\t%s\n" "$now" "$GITHUB_USER" "$repo_name" "$closed_prs"
            ;;
        markdown)
            echo "#### ${repo_name}"
            echo "- Stars: ${stars}"
            echo "- Forks: ${forks}"
            echo "- Open Issues: ${issues}"
            echo "- Watchers: ${watchers}"
            echo "- Open PRs: ${open_prs}"
            echo "- Closed PRs: ${closed_prs}"
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
    tsv)
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
