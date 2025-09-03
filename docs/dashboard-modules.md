# Dashboard Modules

Modules are the heart of the Dashboard project. Each module is an independent, executable script responsible for fetching and formatting data for a single service.

## How Modules Work

- Each file in the `modules/` directory is treated as a module.
- The main `dashboard.sh` script executes each module and passes the desired output format as the first command-line argument (e.g., `json`, `plain`).
- Modules must source the `config/config.sh` file to access the necessary configuration variables. The path to the config file can be found relative to the module script's own location.
- Modules should be written in Bash and be compatible with version 3.2.
- Each module is responsible for its own data fetching (using `curl`) and parsing (using `jq`).

## Creating a New Module

To add a new service to the dashboard, you can create a new module file in the `modules/` directory. Here is a basic template for a new module:

```bash
#!/bin/bash
#
# modules/mynewservice.sh
#
# A brief description of your new module.
#

# --- Configuration and Setup ---

# Find and load the main config file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Config file not found" >&2
    exit 1
fi

# Check for required config variables
if [ -z "$MY_SERVICE_USER" ]; then
    # Exit gracefully if this is an optional module
    exit 0
fi

# --- Input ---

FORMAT="$1"
if [ -z "$FORMAT" ]; then
    echo "Usage: $(basename "$0") <format>" >&2
    exit 1
fi

# --- Data Fetching ---

# Use curl and jq to get your data
DATA=$(curl -s "https://api.myservice.com/user/${MY_SERVICE_USER}" | jq -r '.metric')

# --- Output Formatting ---

case "$FORMAT" in
    plain)
        echo "My New Service"
        echo "Metric: $DATA"
        ;;
    json)
        echo "\"mynewservice\":{\"metric\":${DATA}}"
        ;;
    # ... implement all other 7 formats ...
    *)
        echo "Error: Unsupported format '$FORMAT'" >&2
        exit 1
        ;;
esac
```

### Key Requirements for New Modules

1.  **Use `.sh` Extension**: All module scripts must end with the `.sh` extension (e.g., `mynewservice.sh`).
2.  **Make it Executable**: `chmod +x modules/mynewservice.sh`
3.  **Handle All 8 Formats**: Your module must correctly format its output for `plain`, `pretty`, `json`, `xml`, `html`, `yaml`, `csv`, and `markdown`.
4.  **Be Robust**: Handle potential errors gracefully (e.g., API failures, missing configuration).
5.  **Be Self-Contained**: Do not introduce new system-level dependencies.

### GitHub Module (`modules/github.sh`)

The `github` module fetches statistics for specified repositories. To ensure it works reliably, you should provide a GitHub Personal Access Token (PAT) via the `GITHUB_TOKEN` variable in your `config/config.sh` file. This helps to avoid the strict rate limits imposed by the GitHub API on unauthenticated requests.
