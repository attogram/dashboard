# Dashboard

![Dashboard Logo](./docs/logos/logo.svg)

**A personal metrics dashboard for open-source creators, right in your terminal.**

Dashboard is a modular, configurable, and robust Bash script that provides a consolidated view of your key metrics from various services like GitHub, Hacker News, and more. With support for multiple output formats including JSON, XML, HTML, and Markdown, you can easily integrate your dashboard into websites, reports, or other tools.

---

## Features

- **Modular Architecture**: Easily add new services by creating new module scripts. Run a full report or just a single module.
- **Multiple Output Formats**: Supports `plain`, `pretty` (with colors), `json`, `xml`, `html`, `yaml`, `csv`, and `markdown`.
- **Configurable**: All settings are controlled via a simple `config.sh` file.
- **Minimal Dependencies**: Requires only `curl` and `jq` to run.
- **Bash v3.2+ Compatible**: Written in pure Bash for maximum compatibility.

## Getting Started

### Prerequisites

- `bash` (version 3.2 or higher)
- `curl`
- `jq`

### Installation

1.  Clone this repository:
    ```bash
    git clone https://github.com/attogram/dashboard.git
    cd dashboard
    ```

2.  Create your configuration file by copying the template:
    ```bash
    cp config.dist.sh config.sh
    ```

3.  Edit `config.sh` with your own usernames and settings.

### Usage

To run a full report in the default `plain` format:
```bash
./dashboard.sh
```

To specify an output format, use the `-f` or `--format` flag:
```bash
./dashboard.sh --format pretty
./dashboard.sh -f json
```

To run only a specific module:
```bash
./dashboard.sh github
./dashboard.sh --format html hackernews
```

## Configuration

All configuration is done in the `config.sh` file.

```bash
# Your Hacker News username
HN_USER="your_username_here"

# Your GitHub username
GITHUB_USER="your_username_here"

# A space-separated list of your key GitHub repositories to track.
REPOS=("your-repo-1" "your-repo-2")

# (Optional) Your Discord Server ID for tracking online members.
DISCORD_SERVER_ID=""

# (Optional) GitHub Personal Access Token (PAT) for the 'github-sponsors' module.
# The token needs the 'read:user' scope.
GITHUB_TOKEN=""
```

## Full Documentation

For more detailed information on the architecture, modules, output formats, and contribution guidelines, please see the [full documentation](./docs/README.md).
