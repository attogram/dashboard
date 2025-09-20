#!/usr/bin/env bash

# reporters/trending.sh
#
# Shows the trending metrics over a given timespan.
# Only shows metrics that have changed.
# Usage: ./dashboard.sh -r trending [days]
#
# If [days] is provided, it shows the change over the last N days.
# If not, it shows the change over all available history.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="${SCRIPT_DIR}/../reports"

if [ ! -d "$REPORTS_DIR" ]; then
    echo "Error: reports directory not found at ${REPORTS_DIR}" >&2
    exit 1
fi

DAYS_AGO=$1
TARGET_FILES=()

ALL_FILES=()
while IFS= read -r file; do
    ALL_FILES+=("$file")
done < <(find "$REPORTS_DIR" -name "*.tsv" -not -name "*:*" -print | sort)


if [ -n "$DAYS_AGO" ]; then
    # Filter by days
    # Check if DAYS_AGO is a number
    if ! [[ "$DAYS_AGO" =~ ^[0-9]+$ ]]; then
        echo "Error: Please provide a valid number of days." >&2
        exit 1
    fi

    CUTOFF_DATE=$(date -d "$DAYS_AGO days ago" +%s)
    for file in "${ALL_FILES[@]}"; do
        FILENAME=$(basename "$file" .tsv)
        # The filename is a timestamp in the format YYYY-MM-DDTHH-MM-SSZ.
        # We normalize it to 'YYYY-MM-DD HH:MM:SS' so that `date -d` can parse it.
        DATE_PART=$(echo "$FILENAME" | cut -d'T' -f1)
        TIME_PART=$(echo "$FILENAME" | cut -d'T' -f2 | sed 's/Z$//')
        TIME_PART_COLONS=$(echo "$TIME_PART" | tr '-' ':')
        FILENAME_FOR_DATE="$DATE_PART $TIME_PART_COLONS"
        FILE_DATE=$(date -d "$FILENAME_FOR_DATE" +%s 2>/dev/null)

        if [ -z "$FILE_DATE" ]; then
            # date command failed to parse, skip this file
            continue
        fi

        if [ "$FILE_DATE" -ge "$CUTOFF_DATE" ]; then
            TARGET_FILES+=("$file")
        fi
    done
else
    # Get all files
    TARGET_FILES=("${ALL_FILES[@]}")
fi

if [ ${#TARGET_FILES[@]} -eq 0 ]; then
    echo "No reports found in the given timespan."
    exit 0
fi

# Use awk to process the tsv files
awk '
BEGIN {
    FS="\t";
    OFS="\t";
    print "Change\tLast Value\tFirst Value\tMetrics";
    print "------\t----------\t-----------\t-------";
}
FNR == 1 { next; } # Skip header row of each file
{
    metric = $2 OFS $3 OFS $4; # module, channel, namespace
    value = $5;
    if (value == "null") {
        value = 0;
    }
    if (!(metric in first_value)) {
        first_value[metric] = value;
    }
    last_value[metric] = value;
}
END {
    for (metric in last_value) {
        # Safeguard for nulls in old reports
        if (first_value[metric] == "null") {
            first_value[metric] = 0;
        }
        if (last_value[metric] == "null") {
            last_value[metric] = 0;
        }
        change = last_value[metric] - first_value[metric];
        if (change != 0) {
            # Add a plus sign for positive changes
            if (change > 0) {
                change_str = "+" change;
            } else {
                change_str = change;
            }
            print change_str, last_value[metric], first_value[metric], metric;
        }
    }
}' "${TARGET_FILES[@]}"
