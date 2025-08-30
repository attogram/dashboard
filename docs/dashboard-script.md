# The Main Script (`dashboard.sh`)

The `dashboard.sh` script is the main entry point for the application. It serves as an orchestrator, responsible for parsing arguments, loading configuration, and running the modules to generate a report.

## Usage

```
./dashboard.sh [options] [module]
```

### Options

-   `-f, --format <format>`: Specify the output format. See [Output Formats](./dashboard-output-formats.md) for a full list of supported formats. If not provided, the default is `plain`.
-   `-h, --help`: Display a help message with usage information and exit.

### Arguments

-   `[module]`: (Optional) The name of a single module to run (e.g., `github`, `hackernews`). If a module name is provided, only that module's report will be generated. If omitted, the script will run all executable modules found in the `modules/` directory.

## Execution Flow

The script follows these steps during execution:

1.  **Argument Parsing**: It first parses any command-line options and arguments to determine the desired output format and whether to run a single module or all of them.

2.  **Configuration Loading**: It checks for the existence of `config.sh`. If the file is not found, it will print an error message and exit. If found, it will source the file to load all the user-defined variables into the script's environment.

3.  **Dependency Check**: It verifies that the required command-line tools, `curl` and `jq`, are installed and available in the system's `PATH`. If a dependency is missing, it will exit with an error.

4.  **Module Execution**:
    - If a single module was requested, it executes only that module's script.
    - If no module was specified, it finds all executable files within the `modules/` directory and runs them one by one.

5.  **Report Aggregation**: The script collects the output from each executed module. For structured formats like `json`, `xml`, and `html`, it wraps the collected outputs with the appropriate root elements and separators to create a single, well-formed document. For simpler formats like `plain` or `csv`, it concatenates the outputs.
