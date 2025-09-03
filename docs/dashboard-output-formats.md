# Dashboard Output Formats

The dashboard supports a wide range of output formats, making it easy to consume the data in different ways. The format can be specified using the `-f` or `--format` flag.

Below are examples of the output from the `hackernews` module for each supported format.

---

### `plain` (Default)

Simple, clean text output suitable for scripting or a quick glance.

```text
Hacker News
Karma: 20
```

---

### `pretty`

Text output enhanced with ANSI colors and bolding for better readability in a terminal.

```text
\e[1mHacker News\e[0m
Karma: 20
```

---

### `json`

A single, well-formed JSON object containing all the metrics. The output from a single module is a fragment that is assembled into a larger object by the main script.

```json
{ "karma": 20 }
```

When run as a full report, the output looks like this:

```json
{
  "github": {
    "repo-1": { ... }
  },
  "hackernews": {
    "karma": 20
  }
}
```

---

### `xml`

A single, well-formed XML document containing all the metrics.

```xml
<hackernews><karma>20</karma></hackernews>
```

---

### `html`

A self-contained HTML document for viewing in a web browser.

```html
<h2>Hacker News</h2>
<ul>
  <li>Karma: 20</li>
</ul>
```

---

### `yaml`

A single, well-formed YAML document.

```yaml
hackernews:
  karma: 20
```

---

### `csv`

Comma-separated values suitable for spreadsheets. The format is `module,key,value`. For modules with nested data, there will be multiple rows.

```csv
hackernews,karma,20
```

---

### `tsv`

Tab-separated values, similar to CSV but using tabs as delimiters. The format is `Date\tmodule\tname\tvalue`.

```tsv
2025-09-03T14:48:11Z	hackernews	karma	20
```

---

### `table`

A human-readable ASCII table, generated from the TSV data.

```
Date                  module      name   value
2025-09-03T14:48:20Z  hackernews  karma  20
```

---

### `markdown`

A GitHub-flavored Markdown document.

```markdown
### Hacker News

- Karma: 20
```
