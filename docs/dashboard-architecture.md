# Dashboard Architecture

The Dashboard project is designed with a simple yet powerful modular architecture. This design makes it easy to extend the dashboard with new services and to maintain the existing codebase.

The core components of the architecture are:

1.  **The Main Runner (`dashboard.sh`)**: This is the entry point of the application. Its primary responsibilities are to parse command-line arguments, load the configuration, and orchestrate the execution of the modules. It is also responsible for assembling the final report by wrapping the module outputs in the correct headers and footers for formats like JSON, XML, and HTML.

2.  **The Configuration File (`config/config.sh`)**: This file is the central point of configuration for the user. It contains all the necessary information for the modules to run, such as usernames, API keys, and other settings. It is sourced by both the main runner and the individual modules.

3.  **The Modules Directory (`modules/`)**: This directory contains an executable script for each service that the dashboard tracks. Each module is a self-contained script that is responsible for:
    - Fetching data from its specific service's API.
    - Formatting the data into all of the 8 supported output formats.
    - Being independently runnable.

This separation of concerns allows for a clean and maintainable codebase. A developer can work on a single module without affecting the rest of the application. It also allows users to run a report for a single module if they wish.
