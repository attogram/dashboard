# Installation

This guide provides step-by-step instructions for installing the Dashboard script and its dependencies.

## Prerequisites

Before you begin, ensure you have the following command-line tools installed on your system:

- **Bash**: Version 3.2 or higher. You can check your version with `bash --version`.
- **Git**: For cloning the repository.
- **curl**: For making HTTP requests to the various APIs.
- **jq**: For parsing JSON data from the APIs.

On most Linux systems, you can install these with your package manager. For example, on Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y bash git curl jq
```

On macOS, these tools are typically pre-installed. You can install `jq` with Homebrew:

```bash
brew install jq
```

## Installation Steps

1.  **Clone the Repository**

    Open your terminal and clone the `dashboard` repository from GitHub to a location of your choice.

    ```bash
    git clone https://github.com/attogram/dashboard.git
    ```

    This will create a `dashboard` directory containing the project files.

2.  **Navigate into the Directory**

    ```bash
    cd dashboard
    ```

3.  **Create Your Configuration File**

    The dashboard is configured using a `config.sh` file. A template is provided as `config/config.dist.sh`. Copy this template to create your own configuration file.

    ```bash
    cp config/config.dist.sh config/config.sh
    ```

4.  **Edit Your Configuration**

    Open the `config/config.sh` file in your favorite text editor. Fill in your usernames for the services you want to track. See the [Configuration Guide](./dashboard-configuration.md) for details on all the available options.

    ```bash
    # Example: nano config/config.sh
    nano config/config.sh
    ```

5.  **Run the Script**

    You are now ready to run the dashboard! You can run the main script directly from the command line.

    ```bash
    ./dashboard.sh
    ```

    By default, this will run a full report in the `plain` text format. To learn about the different output formats and how to run specific modules, see the [Main Script Guide](./dashboard-script.md).
