[![Run Tests](https://github.com/attogram/dashboard/actions/workflows/ci.yml/badge.svg)](https://github.com/attogram/dashboard/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/attogram/dashboard?style=flat)](https://github.com/attogram/dashboard/releases)
[![GitHub stars](https://img.shields.io/github/stars/attogram/dashboard?style=flat)](https://github.com/attogram/dashboard/stargazers)
[![GitHub watchers](https://img.shields.io/github/watchers/attogram/dashboard?style=flat)](https://github.com/attogram/dashboard/watchers)
[![Forks](https://img.shields.io/github/forks/attogram/dashboard?style=flat)](https://github.com/attogram/dashboard/forks)
[![Issues](https://img.shields.io/github/issues/attogram/dashboard?style=flat)](https://github.com/attogram/dashboard/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/t/attogram/dashboard?style=flat)](https://github.com/attogram/dashboard/commits/main/)
[![License](https://img.shields.io/github/license/attogram/dashboard?style=flat)](./LICENSE)

# Dashboard

![Dashboard Logo](./docs/logos/logo.320.160.png)

A metrics tool for open-source creators.

Dashboard is a modular, configurable, and robust Bash script that provides a consolidated view of your key metrics from various services like GitHub, Hacker News, and more. With support for multiple output formats including JSON, XML, HTML, and Markdown, you can easily integrate your dashboard into websites, reports, or other tools.

## Example output

```bash
./dashboard.sh -f tsv
```

```csv
date    module    channels    namespace    value
2025-09-01T20:28:46Z    discord    online    discord    3
2025-09-01T20:28:46Z    github    stars    repo.attogram.games    135
2025-09-01T20:28:46Z    github    forks    repo.attogram.games    68
2025-09-01T20:28:46Z    github    open_issues    repo.attogram.games    1
2025-09-01T20:28:46Z    github    watchers    repo.attogram.games    7
2025-09-01T20:28:47Z    github    stars    repo.attogram.EightQueens    15
2025-09-01T20:28:47Z    github    forks    repo.attogram.EightQueens    4
2025-09-01T20:28:47Z    github    open_issues    repo.attogram.EightQueens    0
2025-09-01T20:28:47Z    github    watchers    repo.attogram.EightQueens    2
2025-09-01T20:28:47Z    github    stars    repo.attogram.base    2
2025-09-01T20:28:47Z    github    forks    repo.attogram.base    1
2025-09-01T20:28:47Z    github    open_issues    repo.attogram.base    0
2025-09-01T20:28:47Z    github    watchers    repo.attogram.base    2
2025-09-01T20:28:48Z    github    stars    repo.attogram.dashboard    1
2025-09-01T20:28:48Z    github    forks    repo.attogram.dashboard    0
2025-09-01T20:28:48Z    github    open_issues    repo.attogram.dashboard    0
2025-09-01T20:28:48Z    github    watchers    repo.attogram.dashboard    1
2025-09-01T20:28:54Z    hackernews    karma    your_username_here    30
```

## Features

- **Modular Architecture**: Easily add new services by creating new module scripts. Run a full report or just a single module.
- **Multiple Output Formats**: Supports `plain`, `pretty` (with colors), `json`, `xml`, `html`, `yaml`, `csv`, `tsv`, `table`, and `markdown`.
- **Configurable**: All settings are controlled via a simple `config/config.sh` file.
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
    cp config/config.dist.sh config/config.sh
    ```

3.  Edit `config/config.sh` with your own usernames and settings.

### Usage

To run a full report in the default `tsv` format:

```bash
./dashboard.sh
```

To specify an output format, use the `-f` or `--format` flag:

```bash
./dashboard.sh --format pretty
./dashboard.sh -f json
```

To save the report to a specific file or directory, use the `-o` or `--output` flag:

```bash
# Save to a specific file
./dashboard.sh -o my_report.tsv

# Save to a directory (a timestamped filename will be generated)
./dashboard.sh -o reports/
```

To run only a specific module:

```bash
./dashboard.sh github
./dashboard.sh --format html hackernews
```

To run a specific reporter:

- **`top-stars`**: Shows the top 10 repositories by stars.
- **`trending`**: Shows the change in metrics over a given timespan. Only shows metrics that have changed.
  - Usage: `./dashboard.sh -r trending [days]`

## Configuration

All configuration is done in the `config/config.sh` file.

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
