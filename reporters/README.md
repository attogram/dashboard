# Reporters

This directory contains scripts that analyze the historical data collected by the modules.

## Known Issues

### Date-based Filtering

The `timespan` reporter is intended to support filtering by a number of days. The `hot` reporter (not yet implemented) would also rely on this functionality.

Currently, this feature is **not functional** due to limitations in the `date` command available in the execution environment. The `date -d` command is unable to parse the ISO-8601-like timestamps from the report filenames, which prevents the scripts from reliably filtering reports by date.

Because of this environmental constraint:

- The `timespan` reporter will always analyze the full history of reports, regardless of the `[days]` argument.
- The `hot` reporter has not been implemented, as its core logic is not possible to build reliably.

This issue will need to be resolved by either fixing the `date` utility in the environment or by providing an alternative date parsing method.
