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

REPORTER_TO_RUN=""
REPORTER_ARGS=()

usage() {
    echo "Usage: $(basename "$0") [options] [module]"
    echo "   or: $(basename "$0") -r <reporter> [reporter_options]"
    echo
    echo "Options:"
    echo "  -f, --format <format>    Set the output format for module runs."
    echo "                           Supported formats: ${VALID_FORMATS[*]}"
    echo "  -r, --reporter <name>    Run a specific reporter."
    echo "  -v, --verbose            Enable verbose (debug) mode."
    echo "  -h, --help               Display this help message."
    echo
    echo "To save a data collection report, redirect the output to a file:"
    echo "  ./dashboard.sh > reports/\$(date -u +%Y-%m-%dT%H:%M:%SZ).tsv"
    echo
    echo "Available modules:"
    local modules=()
    for module in "${SCRIPT_DIR}/modules"/*; do
        if [ -x "$module" ]; then
            modules+=("$(basename "$module" .sh)")
        fi
    done
    echo "  ${modules[*]}"
    echo
    echo "Available reporters:"
    local reporters=()
    for reporter in "${SCRIPT_DIR}/reporters"/*.sh; do
        if [ -x "$reporter" ]; then
            reporters+=("$(basename "$reporter" .sh)")
        fi
    done
    echo "  ${reporters[*]}"
    echo
    echo "If a module name (e.g., 'github') is provided, only that module will be run."
    echo "If a reporter is specified with -r, it will be run with any subsequent arguments."
}

_debug "$DASHBOARD_NAME v$DASHBOARD_VERSION"

_debug 'parsing command-line arguments'

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -r|--reporter)
            REPORTER_TO_RUN="$2"
            shift 2
            REPORTER_ARGS=("$@")
            break # Stop parsing, the rest of the args are for the reporter
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -v|--verbose)
            DASHBOARD_DEBUG=1
            shift
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

# --- Main Execution Flow ----------------------------------------------------

if [ -n "$REPORTER_TO_RUN" ]; then
    # --- Reporter Execution -------------------------------------------------
    _debug "Attempting to run reporter: $REPORTER_TO_RUN"
    REPORTER_PATH="${SCRIPT_DIR}/reporters/${REPORTER_TO_RUN}.sh"
    if [ ! -f "$REPORTER_PATH" ]; then
        # try without .sh extension for convenience
        REPORTER_PATH="${SCRIPT_DIR}/reporters/${REPORTER_TO_RUN}"
        if [ ! -f "$REPORTER_PATH" ]; then
            _error "Error: Reporter '${REPORTER_TO_RUN}' not found."
            exit 1
        fi
    fi

    if [ ! -x "$REPORTER_PATH" ]; then
        _error "Error: Reporter '${REPORTER_TO_RUN}' is not executable."
        exit 1
    fi

    _debug "Executing reporter '$REPORTER_PATH' with args: ${REPORTER_ARGS[*]}"
    # shellcheck source=/dev/null
    "$REPORTER_PATH" "${REPORTER_ARGS[@]}"

else
    # --- Module Data Collection ---------------------------------------------
    _debug 'Validate format'
    if ! [[ " ${VALID_FORMATS[*]} " =~ " ${FORMAT} " ]]; then
        _error "Error: Invalid format '${FORMAT}'."
        usage
        exit 1
    fi

    MODULE_EXEC_FORMAT="tsv"

    _debug 'Load configuration'
    if [ -f "${SCRIPT_DIR}/config/config.sh" ]; then
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

    generate_report() {
        # The OUTPUTS array contains TSV data from the modules.
        # We now format it based on the user's requested FORMAT.

        # First, combine all output into a single string with a header.
        local all_tsv_data
        all_tsv_data=$(echo -e "date\tmodule\tchannels\tnamespace\tvalue"; printf '%s\n' "${OUTPUTS[@]}")

        case "$FORMAT" in
            tsv)
                echo "$all_tsv_data"
                ;;
            csv)
                echo "$all_tsv_data" | sed 's/\t/,/g'
                ;;
            table)
                if ! command -v awk &> /dev/null; then
                    _warn "'awk' command not found. Falling back to tsv format."
                    echo "$all_tsv_data"
                else
                    echo "$all_tsv_data" | awk '
                        BEGIN {
                            FS="\t"
                        }
                        {
                            for (i=1; i<=NF; i++) {
                                if (length($i) > max[i]) {
                                    max[i] = length($i)
                                }
                                data[NR][i] = $i
                            }
                        }
                        END {
                            # Print top border
                            for (i=1; i<=NF; i++) {
                                printf "+-"
                                for (j=1; j<=max[i]; j++) printf "-"
                                printf "-"
                            }
                            printf "+\n"

                            # Print header
                            for (i=1; i<=NF; i++) {
                                printf "| %-" max[i] "s ", data[1][i]
                            }
                            printf "|\n"

                            # Print separator
                            for (i=1; i<=NF; i++) {
                                printf "+-"
                                for (j=1; j<=max[i]; j++) printf "-"
                                printf "-"
                            }
                            printf "+\n"

                            # Print data
                            for (row=2; row<=NR; row++) {
                                for (i=1; i<=NF; i++) {
                                    printf "| %-" max[i] "s ", data[row][i]
                                }
                                printf "|\n"
                            }

                            # Print bottom border
                            for (i=1; i<=NF; i++) {
                                printf "+-"
                                for (j=1; j<=max[i]; j++) printf "-"
                                printf "-"
                            }
                            printf "+\n"
                        }
                    '
                fi
                ;;
            json)
                if ! command -v awk &> /dev/null; then
                     _warn "'awk' command not found. Cannot generate JSON."
                     return
                fi
                # Use jq to pretty-print if available, otherwise just output compact json
                local json_output
                _debug "TSV data for JSON conversion:\n$all_tsv_data"
                json_output=$(echo "$all_tsv_data" | awk -F'\t' '
                BEGIN {
                    printf "["
                }
                NR > 1 { # Skip header
                    if (NR > 2) { printf "," }
                    for(i=1; i<=NF; i++) { gsub(/"/, "\\\"", $i) }

                    if ($5 == "null") {
                        printf "{\"date\":\"%s\",\"module\":\"%s\",\"channels\":\"%s\",\"namespace\":\"%s\",\"value\":null}", $1, $2, $3, $4
                    } else if ($5 != "" && $5 == $5+0) {
                        printf "{\"date\":\"%s\",\"module\":\"%s\",\"channels\":\"%s\",\"namespace\":\"%s\",\"value\":%s}", $1, $2, $3, $4, $5
                    } else {
                        printf "{\"date\":\"%s\",\"module\":\"%s\",\"channels\":\"%s\",\"namespace\":\"%s\",\"value\":\"%s\"}", $1, $2, $3, $4, $5
                    }
                }
                END {
                    printf "]"
                }')
                if command -v jq &> /dev/null; then
                    echo "$json_output" | jq .
                else
                    echo "$json_output"
                fi
                ;;
            xml)
                echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><dashboard>"
                echo "$all_tsv_data" | awk -F'\t' '
                NR > 1 { # Skip header
                    printf "<metric><date>%s</date><module>%s</module><channels>%s</channels><namespace>%s</namespace><value>%s</value></metric>\n", $1, $2, $3, $4, $5
                }'
                echo "</dashboard>"
                ;;
            html)
                 echo "<!DOCTYPE html><html><head><title>Dashboard</title></head><body><table>"
                 echo "<tr><th>Date</th><th>Module</th><th>Channels</th><th>Namespace</th><th>Value</th></tr>"
                 echo "$all_tsv_data" | awk -F'\t' '
                 NR > 1 { # Skip header
                    printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5
                 }'
                 echo "</table></body></html>"
                 ;;
            *)
                # For plain, pretty, yaml, markdown, just show the TSV for now.
                echo "$all_tsv_data"
                ;;
        esac
    }

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
        # Defined order of execution
        ORDERED_MODULES=("github.sh" "hackernews.sh" "discord.sh" "github-sponsors.sh" "crypto.sh")
        for module in "${ORDERED_MODULES[@]}"; do
            if [ -x "${MODULES_DIR}/${module}" ]; then
                MODULES_TO_RUN+=("$module")
            fi
        done
    fi

    _debug "MODULES_TO_RUN: ${MODULES_TO_RUN[*]}"

    _debug 'Collect output from all modules'
    OUTPUTS=()
    for module_name in "${MODULES_TO_RUN[@]}"; do
        _debug "Calling $module_name"
        module_output=$("$MODULES_DIR/$module_name" "$MODULE_EXEC_FORMAT" 2>/dev/null)
        if [ -n "$module_output" ]; then
            _debug "Saving output from $module_name: $(echo "$module_output" | wc -c | tr -d ' ') bytes"
            OUTPUTS+=("$module_output")
        fi
    done

    generate_report
fi

_debug 'Done.'
