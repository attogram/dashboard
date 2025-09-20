# Overviews

Overviews are scripts that analyze the historical data collected by the modules. While the modules are responsible for _gathering_ data, overviews are responsible for _interpreting_ it.

## How to Run an Overview

You can run any overview using the `-o` flag on the main `dashboard.sh` script:

```bash
./dashboard.sh -o <overview_name> [overview_options]
```

For example, to run the `top-stars` overview, you would use:

```bash
./dashboard.sh -o top-stars
```

Some overviews accept their own arguments, which you can pass after the overview's name:

```bash
./dashboard.sh -o top-stars 5
```

## Available Overviews

Here is a list of the currently available overviews.

### `trending`

The `trending` overview shows the change in each metric over a period of time, but it only includes metrics that have actually changed. It reads all the `.tsv` report files from the `reports/` directory and calculates the difference between the first and last recorded values for each metric, filtering out any that have a change of zero.

**Usage:**

```bash
./dashboard.sh -o trending [days]
```

- **`[days]`** (optional): The number of days of history to analyze.

**Behavior:**

- If `[days]` is not provided, it will analyze all reports in your `reports/` directory to show the all-time change.
- If `[days]` is provided, it will show the change over the last `N` days.

**Example Output:**

```
Change	Last Value	First Value	Metrics
------	----------	-----------	-------
-1	0	1	github	open_issues	repo.attogram.agents
-15	0	15	github	closed_prs	repo.attogram.ote
-1	0	1	github	open_prs	repo.attogram.agents
-13	0	13	github	closed_prs	repo.attogram.justrefs
+6	10	4	github	stars	repo.attogram.llm-council
```

### `top-stars`

The `top-stars` overview finds the most recent report file and lists the top repositories by their star count.

**Usage:**

```bash
./dashboard.sh -o top-stars [count]
```

- **`[count]`** (optional): The number of top repositories to display. Defaults to 10.

**Example Output:**

```
Top 10 repositories by stars (from 2025-09-10_18-52-24.tsv)
----------------------------------------------------
Rank    Stars   Repository
1       1       attogram/dashboard
```

## Creating Your Own Overview

You can easily create your own overview by adding a new executable shell script to the `overviews/` directory.

An overview script should:

1.  Be placed in the `overviews/` directory.
2.  Be executable (`chmod +x overviews/my_overview.sh`).
3.  Read data from the `.tsv` files in the `reports/` directory. The path to the reports directory can be found relative to the script's own location: `REPORTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../reports"`.
4.  Parse its own arguments if needed.
5.  Print its analysis to standard output.
