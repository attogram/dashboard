#!/usr/bin/env bash

# reporters/top-stars.sh
#
# Shows the top repositories by star count from the latest report.
# Usage: ./dashboard.sh -r top-stars [count]
#
# If [count] is provided, it shows the top N repos.
# If not, it defaults to 10.

COUNT=${1:-10} # Default to 10 if no argument is provided

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="${SCRIPT_DIR}/../reports"

if [ ! -d "$REPORTS_DIR" ]; then
    echo "Error: reports directory not found at ${REPORTS_DIR}" >&2
    exit 1
fi

# Find the latest report file (ignoring ones with colons)
LATEST_REPORT=$(find "$REPORTS_DIR" -name "*.tsv" -not -name "*:*" -print | sort | tail -n 1)

if [ -z "$LATEST_REPORT" ]; then
    echo "No reports found."
    exit 0
fi

echo "Top ${COUNT} repositories by stars (from $(basename "$LATEST_REPORT"))"
echo "----------------------------------------------------"
echo -e "Rank\tStars\tRepository"

# Process the latest report
# 1. grep for github stars lines
# 2. sort by the 5th field (value) numerically and in reverse
# 3. take the top COUNT lines
# 4. use awk to format the output
grep 'github	stars' "$LATEST_REPORT" | \
    sort -t$'\t' -k5 -nr | \
    head -n "$COUNT" | \
    awk -F'\t' '{
        # The repo name is in the 4th column, like "repo.owner.name"
        # We want to extract "owner/name"
        split($4, parts, ".")
        repo_name = parts[2] "/" parts[3]
        printf "%s\t%s\t%s\n", NR, $5, repo_name
    }'
