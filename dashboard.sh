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

DASHBOARD_NAME='dashboard'
DASHBOARD_VERSION='0.0.2'
DASHBOARD_URL='https://github.com/attogram/dashboard'
DASHBOARD_DISCORD='https://discord.gg/BGQJCbYVBa'
DASHBOARD_LICENSE='MIT'
DASHBOARD_COPYRIGHT='Copyright (c) 2025 Attogram Project <https://github.com/attogram>'
DASHBOARD_DEBUG=0 # 0 = off, 1 = on

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMAT="tsv"
MODULE_TO_RUN=""
VALID_FORMATS=("plain" "pretty" "json" "xml" "html" "yaml" "csv" "markdown" "tsv" "table")

_debug() {
  (( DASHBOARD_DEBUG )) || return 0
  printf '[DEBUG] %s: %s\n' "$(date '+%H:%M:%S')" "$1" >&2
}

_message() {
  printf '%s\n' "$1"
}

_warn() {
  printf '[WARNING] %s\n' "$1" >&2
}

_error() {
  printf '[ERROR] %s\n' "$1" >&2
}

usage() {
    echo "Usage: $(basename "$0") [options] [module]"
    echo "Options:"
    echo "  -f, --format <format>  Set the output format."
    echo "                         Supported formats: ${VALID_FORMATS[*]}"
    echo "  -h, --help             Display this help message."
    echo
    echo "If a module name (e.g., 'github') is provided, only that module will be run."
}

_debug "$DASHBOARD_NAME v$DASHBOARD_VERSION"

_debug 'parsing command-line arguments'

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
                _error "Unknown option: $1"
                usage
                exit 1
            fi
            ;;
    esac
done

_debug 'Validate format'
if ! [[ " ${VALID_FORMATS[*]} " =~ " ${FORMAT} " ]]; then
    _error "Error: Invalid format '${FORMAT}'."
    usage
    exit 1
fi

MODULE_EXEC_FORMAT=$FORMAT
if [ "$FORMAT" = "table" ]; then
    MODULE_EXEC_FORMAT="tsv"
fi


_debug 'Load configuration'
if [ -f "${SCRIPT_DIR}/config.sh" ]; then
    # shellcheck source=config.sh
    source "${SCRIPT_DIR}/config.sh"
else
    _error "Error: Configuration file not found."
    _error "Please copy config.dist.sh to config.sh and customize it."
    exit 1
fi

_debug 'Check for dependencies'
if ! command -v curl &> /dev/null; then
    _error "Error: 'curl' is not installed or not in your PATH."
    exit 1
fi
if ! command -v jq &> /dev/null; then
    _error "Error: 'jq' is not installed or not in your PATH."
    exit 1
fi


_debug 'Get list of modules to run'
MODULES_DIR="${SCRIPT_DIR}/modules"
MODULES_TO_RUN=()
if [ -n "$MODULE_TO_RUN" ]; then
    # If the user provides 'github', check for 'github.sh'
    if [[ ! "$MODULE_TO_RUN" == *.sh ]]; then
        MODULE_TO_RUN="${MODULE_TO_RUN}.sh"
    fi
    MODULE_PATH="${MODULES_DIR}/${MODULE_TO_RUN}"
    if [ ! -x "$MODULE_PATH" ]; then
        # If 'github.sh' is not found, try without the extension for backward compatibility
        MODULE_TO_RUN_NO_EXT="${MODULE_TO_RUN%.sh}"
        MODULE_PATH_NO_EXT="${MODULES_DIR}/${MODULE_TO_RUN_NO_EXT}"
        if [ -x "$MODULE_PATH_NO_EXT" ]; then
            MODULE_PATH="$MODULE_PATH_NO_EXT"
            MODULE_TO_RUN="$MODULE_TO_RUN_NO_EXT"
        else
            _error "Error: Module '${MODULE_TO_RUN}' not found or not executable."
            exit 1
        fi
    fi
    MODULES_TO_RUN+=("$MODULE_TO_RUN")
else
    # Find all executable files in the modules directory, with or without .sh
    for module in "${MODULES_DIR}"/*; do
        if [ -x "$module" ]; then
            MODULES_TO_RUN+=("$(basename "$module")")
        fi
    done
fi

_debug "MODULES_TO_RUN: ${MODULES_TO_RUN[*]}"

_debug 'Collect output from all modules'
OUTPUTS=()
for module_name in "${MODULES_TO_RUN[@]}"; do
    _debug "Calling $module_name"
    module_output=$("$MODULES_DIR/$module_name" "$MODULE_EXEC_FORMAT")
    if [ -n "$module_output" ]; then
        _debug "Saving output from $module_name: $(echo "$module_output" | wc -c | tr -d ' ') bytes"
        OUTPUTS+=("$module_output")
    fi
done

_debug "Assemble the final report: FORMAT: $FORMAT"

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
    tsv)
        echo -e "Date\tmodule\tname\tvalue"
        printf '%s\n' "${OUTPUTS[@]}"
        ;;
    table)
        if ! command -v column &> /dev/null; then
            _warn "'column' command not found. Falling back to tsv format."
            echo -e "Date\tmodule\tname\tvalue"
            printf '%s\n' "${OUTPUTS[@]}"
        else
            (echo -e "Date\tmodule\tname\tvalue"; printf '%s\n' "${OUTPUTS[@]}") | column -t -s $'\t'
        fi
        ;;
    *)
        # For plain, pretty, yaml, markdown, just print the outputs
        printf '%s\n' "${OUTPUTS[@]}"
        ;;
esac

_debug 'Done.'
