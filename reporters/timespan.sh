#!/usr/bin/env bash

# reporters/timespan.sh
#
# Shows the change in metrics over a given timespan.
# Usage: ./dashboard.sh -r timespan [days]
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
        # The filename is a timestamp. It can be in various formats.
        # We normalize it to a format that `date -d` can handle.
        FILENAME_FOR_DATE=$(echo "$FILENAME" | sed 's/_/T/')
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
    print "Metric\tFirst Value\tLast Value\tChange";
    print "------\t-----------\t----------\t------";
}
FNR == 1 { next; } # Skip header row of each file
{
    metric = $2 OFS $3 OFS $4; # module, channel, namespace
    value = $5;
    if (!(metric in first_value)) {
        first_value[metric] = value;
    }
    last_value[metric] = value;
}
END {
    for (metric in last_value) {
        change = last_value[metric] - first_value[metric];
        # Add a plus sign for positive changes
        if (change > 0) {
            change_str = "+" change;
        } else {
            change_str = change;
        }
        print metric, first_value[metric], last_value[metric], change_str;
    }
}' "${TARGET_FILES[@]}"
