#!/bin/bash
#
# dashboard.sh
#
# Personal metrics dashboard for open-source creators.
#
# Usage: ./dashboard.sh [options] [module]
#
# Options:
#   -f, --format <format>  Output format (plain, pretty, json, xml, html, yaml, csv, markdown)
#   -h, --help             Display this help message
#

# --- Configuration and Setup ------------------------------------------------

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default format and module
FORMAT="plain"
MODULE_TO_RUN=""
VALID_FORMATS=("plain" "pretty" "json" "xml" "html" "yaml" "csv" "markdown")

# --- Functions --------------------------------------------------------------

# Display usage information
usage() {
    echo "Usage: $(basename "$0") [options] [module]"
    echo "Options:"
    echo "  -f, --format <format>  Set the output format."
    echo "                         Supported formats: ${VALID_FORMATS[*]}"
    echo "  -h, --help             Display this help message."
    echo
    echo "If a module name (e.g., 'github') is provided, only that module will be run."
}

# --- Argument Parsing -------------------------------------------------------

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -f|--format)
        FORMAT="$2"
        shift 2
        ;;
        -h|--help)
        usage
        exit 0
        ;;
        *)
        if [[ -z "$MODULE_TO_RUN" ]] && [[ ! "$key" == -* ]]; then
            MODULE_TO_RUN="$key"
            shift
        else
            echo "Unknown option: $1"
            usage
            exit 1
        fi
        ;;
    esac
done

# Validate format
if ! [[ " ${VALID_FORMATS[*]} " =~ " ${FORMAT} " ]]; then
    echo "Error: Invalid format '${FORMAT}'."
    usage
    exit 1
fi

# --- Initialization ---------------------------------------------------------

# Load configuration
if [ -f "${SCRIPT_DIR}/config.sh" ]; then
    # shellcheck source=config.sh
    source "${SCRIPT_DIR}/config.sh"
else
    echo "Error: Configuration file not found."
    echo "Please copy config.dist.sh to config.sh and customize it."
    exit 1
fi

# Check for dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' is not installed or not in your PATH."
    exit 1
fi
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed or not in your PATH."
    exit 1
fi

# --- Main Logic -------------------------------------------------------------

# Get list of modules to run
MODULES_DIR="${SCRIPT_DIR}/modules"
MODULES_TO_RUN=()
if [ -n "$MODULE_TO_RUN" ]; then
    MODULE_PATH="${MODULES_DIR}/${MODULE_TO_RUN}"
    if [ ! -x "$MODULE_PATH" ]; then
        echo "Error: Module '${MODULE_TO_RUN}' not found or not executable."
        exit 1
    fi
    MODULES_TO_RUN+=("$MODULE_TO_RUN")
else
    for module in "${MODULES_DIR}"/*; do
        if [ -x "$module" ]; then
            MODULES_TO_RUN+=("$(basename "$module")")
        fi
    done
fi

# --- Report Generation ------------------------------------------------------

# Collect output from all modules
OUTPUTS=()
for module_name in "${MODULES_TO_RUN[@]}"; do
    module_output=$("$MODULES_DIR/$module_name" "$FORMAT")
    if [ -n "$module_output" ]; then
        OUTPUTS+=("$module_output")
    fi
done

# Assemble the final report
case "$FORMAT" in
    json)
        echo "{"
        printf '%s,' "${OUTPUTS[@]}" | sed 's/,$//'
        echo "}"
        ;;
    xml)
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><dashboard>"
        printf '%s\n' "${OUTPUTS[@]}"
        echo "</dashboard>"
        ;;
    html)
        echo "<!DOCTYPE html><html><head><title>Dashboard</title></head><body>"
        printf '%s\n' "${OUTPUTS[@]}"
        echo "</body></html>"
        ;;
    csv)
        echo "module,key,value"
        printf '%s\n' "${OUTPUTS[@]}"
        ;;
    *)
        # For plain, pretty, yaml, markdown, just print the outputs
        printf '%s\n' "${OUTPUTS[@]}"
        ;;
esac
