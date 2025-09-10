# Reporters

Reporters are scripts that analyze the historical data collected by the modules. While the modules are responsible for _gathering_ data, reporters are responsible for _interpreting_ it.

## How to Run a Reporter

You can run any reporter using the `-r` flag on the main `dashboard.sh` script:

```bash
./dashboard.sh -r <reporter_name> [reporter_options]
```

For example, to run the `top-stars` reporter, you would use:

```bash
./dashboard.sh -r top-stars
```

Some reporters accept their own arguments, which you can pass after the reporter's name:

```bash
./dashboard.sh -r top-stars 5
```

## Available Reporters

Here is a list of the currently available reporters.

### `timespan`

The `timespan` reporter shows the change in each metric over a period of time. It reads all the `.tsv` report files from the `reports/` directory and calculates the difference between the first and last recorded values for each metric.

**Usage:**

```bash
./dashboard.sh -r timespan [days]
```

- **`[days]`** (optional): The number of days of history to analyze.

**Behavior:**

- If `[days]` is not provided, it will analyze all reports in your `reports/` directory to show the all-time change.
- If `[days]` is provided, it will show the change over the last `N` days.

**Note on `[days]` filtering:** This feature is currently not working as expected due to limitations in the `date` command of the execution environment. The script is unable to parse dates from the report filenames reliably. At present, the `timespan` reporter will always show the all-time history regardless of this argument.

### `top-stars`

The `top-stars` reporter finds the most recent report file and lists the top repositories by their star count.

**Usage:**

```bash
./dashboard.sh -r top-stars [count]
```

- **`[count]`** (optional): The number of top repositories to display. Defaults to 10.

**Example Output:**

```
Top 10 repositories by stars (from 2025-09-10_18-52-24.tsv)
----------------------------------------------------
Rank    Stars   Repository
1       1       attogram/dashboard
```

## Creating Your Own Reporter

You can easily create your own reporter by adding a new executable shell script to the `reporters/` directory.

A reporter script should:

1.  Be placed in the `reporters/` directory.
2.  Be executable (`chmod +x reporters/my_reporter.sh`).
3.  Read data from the `.tsv` files in the `reports/` directory. The path to the reports directory can be found relative to the script's own location: `REPORTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../reports"`.
4.  Parse its own arguments if needed.
5.  Print its analysis to standard output.
