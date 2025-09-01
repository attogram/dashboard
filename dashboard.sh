#!/usr/bin/env bash
#
# dashboard.sh
#
# Personal metrics dashboard for open-source creators.
#
# Usage: ./dashboard.sh [options] [module]
#
# Options:
#   -f, --format <format>  Output format (plain, pretty, json, xml, html, yaml, csv, markdown)
#   -d, --debug            Enable debug mode
#   -v, --version          Show version information
#   -h, --help             Display this help message
#

dashboard_name='dashboard'
dashboard_version='0.0.2'
dashboard_url='https://github.com/attogram/dashboard'
dashboard_discord='https://discord.gg/BGQJCbYVBa'
dashboard_license='MIT'
dashboard_copyright='Copyright (c) 2025 Attogram Project <https://github.com/attogram>'
dashboard_debug=0 # 0 = off, 1 = on

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
format="plain"
module_to_run=""
valid_formats=("plain" "pretty" "json" "xml" "html" "yaml" "csv" "markdown")

_debug() {
  (( dashboard_debug )) || return 0
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
    echo "Usage: ${0##*/} [options] [module]"
    echo "Options:"
    echo "  -f, --format <format>  Set the output format."
    echo "                         Supported formats: ${valid_formats[*]}"
    echo "  -d, --debug            Enable debug mode."
    echo "  -v, --version          Show version information."
    echo "  -h, --help             Display this help message."
    echo
    echo "Available Modules:"
    for module in "${SCRIPT_DIR}/modules"/*; do
        if [[ -x "$module" ]]; then
            module_name=${module##*/}
            echo "  ${module_name%.sh}"
        fi
    done
    echo
    echo "If a module name is provided, only that module will be run."
}

_debug "$dashboard_name v$dashboard_version"

_debug 'parsing command-line arguments'

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -f|--format)
            format="$2"
            shift 2
            ;;
        -d|--debug)
            dashboard_debug=1
            shift
            ;;
        -v|--version)
            echo "$dashboard_name v$dashboard_version"
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$module_to_run" && ! "$key" == -* ]]; then
                module_to_run="$key"
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
if ! [[ " ${valid_formats[*]} " =~ " ${format} " ]]; then
    _error "Error: Invalid format '${format}'."
    usage
    exit 1
fi


_debug 'Load configuration'
if [[ -f "${SCRIPT_DIR}/config/config.sh" ]]; then
    # shellcheck source=config/config.sh
    source "${SCRIPT_DIR}/config/config.sh"
else
    _error "Error: Configuration file not found."
    _error "Please copy config/config.dist.sh to config/config.sh and customize it."
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
modules_dir="${SCRIPT_DIR}/modules"
modules_to_run=()
if [[ -n "$module_to_run" ]]; then
    # If the user provides 'github', check for 'github.sh'
    if [[ ! "$module_to_run" == *.sh ]]; then
        module_to_run="${module_to_run}.sh"
    fi
    module_path="${modules_dir}/${module_to_run}"
    if [[ ! -x "$module_path" ]]; then
        # If 'github.sh' is not found, try without the extension for backward compatibility
        module_to_run_no_ext="${module_to_run%.sh}"
        module_path_no_ext="${modules_dir}/${module_to_run_no_ext}"
        if [[ -x "$module_path_no_ext" ]]; then
            module_path="$module_path_no_ext"
            module_to_run="$module_to_run_no_ext"
        else
            _error "Error: Module '${module_to_run}' not found or not executable."
            exit 1
        fi
    fi
    modules_to_run+=("$module_to_run")
else
    # Find all executable files in the modules directory, with or without .sh
    for module in "${modules_dir}"/*; do
        if [[ -x "$module" ]]; then
            modules_to_run+=("$(basename "$module")")
        fi
    done
fi

_debug "modules_to_run: ${modules_to_run[*]}"

_debug 'Collect output from all modules'
outputs=()
for module_name in "${modules_to_run[@]}"; do
    _debug "Calling $module_name"
    module_output=$("$modules_dir/$module_name" "$format")
    if [[ -n "$module_output" ]]; then
        _debug "Saving output from $module_name: $(echo "$module_output" | wc -c | tr -d ' ') bytes"
        outputs+=("$module_output")
    fi
done

_debug "Assemble the final report: format: $format"

timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

case "$format" in
    json)
        echo "{"
        echo "\"timestamp\":\"${timestamp}\","
        printf '%s,' "${outputs[@]}" | sed 's/,$//'
        echo "}"
        ;;
    xml)
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><dashboard>"
        echo "  <timestamp>${timestamp}</timestamp>"
        printf '%s\n' "${outputs[@]}"
        echo "</dashboard>"
        ;;
    html)
        echo "<!DOCTYPE html><html><head><title>Dashboard</title></head><body>"
        echo "  <p>Report generated at: ${timestamp}</p>"
        printf '%s\n' "${outputs[@]}"
        echo "</body></html>"
        ;;
    csv)
        echo "module,key,value"
        printf '%s\n' "${outputs[@]}"
        ;;
    yaml)
        echo "timestamp: \"${timestamp}\""
        printf '%s\n' "${outputs[@]}"
        ;;
    markdown)
        echo "_Report generated at: ${timestamp}_"
        echo ""
        printf '%s\n' "${outputs[@]}"
        ;;
    *)
        # For plain and pretty
        echo "Report generated at: ${timestamp}"
        printf '%s\n' "${outputs[@]}"
        ;;
esac

_debug 'Done.'
