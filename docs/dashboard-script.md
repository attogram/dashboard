# The Main Script (`dashboard.sh`)

The `dashboard.sh` script is the main entry point for the application. It serves as an orchestrator, responsible for parsing arguments, loading configuration, and running modules for data collection, or running reporters for data analysis.

## Usage

To collect data from modules:

```
./dashboard.sh [options] [module]
```

To run a reporter:

```
./dashboard.sh -r <reporter_name> [reporter_options]
```

### Options

- `-f, --format <format>`: (For module runs only) Specify the output format. See [Output Formats](./dashboard-output-formats.md) for a full list of supported formats. If not provided, the default is `tsv`.
- `-r, --reporter <name>`: Run a specific reporter from the `reporters/` directory. Any subsequent arguments will be passed to the reporter script.
- `-v, --verbose`: Enable verbose (debug) mode, which prints detailed messages about the script's execution to standard error.
- `-h, --help`: Display a help message with usage information and exit.

### Arguments

- `[module]`: (Optional, for module runs only) The name of a single module to run (e.g., `github`, `hackernews`). If a module name is provided, only that module's data will be collected. If omitted, the script will run all executable modules found in the `modules/` directory.

## Execution Flow

The script has two main modes of operation: data collection and reporting.

### Data Collection Mode

This is the default mode when the `-r` flag is not used.

1.  **Argument Parsing**: It parses command-line options (`-f`, `-h`) and an optional module name.

2.  **Configuration Loading**: It checks for the existence of `config/config.sh`. If the file is not found, it will print an error message and exit. If found, it will source the file to load all the user-defined variables into the script's environment.

3.  **Dependency Check**: It verifies that the required command-line tools, `curl` and `jq`, are installed and available in the system's `PATH`.

4.  **Module Execution**:
    - If a single module was requested, it executes only that module's script.
    - If no module was specified, it finds all executable files within the `modules/` directory and runs them one by one.

5.  **Report Generation**: The script collects the output from each executed module. For structured formats like `json`, `xml`, and `html`, it wraps the collected outputs with the appropriate root elements. For simpler formats like `plain` or `csv`, it concatenates the outputs. The final report is printed to standard output, which can be redirected to a file.

### Reporter Mode

This mode is triggered by the `-r` flag.

1.  **Argument Parsing**: The script looks for the `-r` flag. When found, it takes the next argument as the reporter's name. All following arguments are passed directly to the reporter.

2.  **Reporter Execution**: The script looks for an executable file with the given name in the `reporters/` directory and runs it, passing along any reporter-specific arguments. The output of the reporter is printed to standard output.
