# Future Plans

This document outlines the roadmap and potential future features for the Dashboard project. This is a living document and is subject to change.

## Immediate Roadmap

These are the features and fixes that are planned for the near future:

- **Implement the Discord Module**: The top priority is to find a stable way to test the Discord API so that the `discord` module can be implemented.
- **Fix XML Tag Bug**: Sanitize repository names in the `github` module to ensure that they are valid XML tag names.
- **Improve XML/HTML Validation**: Investigate ways to add more robust XML and HTML validation to the integration tests, potentially by installing a linter like `xmllint` in the CI environment.

## Potential Future Modules

The modular architecture makes it easy to add new services. Here are some ideas for future modules:

- **Twitter/X**: Track follower count, likes, and retweets.
- **YouTube**: Track subscriber count, views, and likes on recent videos.
  -- **Patreon**: Track the number of patrons and monthly income.
- **npm**: Track download stats for your packages.
- **PyPI**: Track download stats for your Python packages.
- **Generic JSON**: A module that can fetch and display data from any arbitrary JSON API endpoint, configured by the user.

## Feature Enhancements

- **Caching**: Implement a caching mechanism to avoid hitting API rate limits and to speed up report generation. The cache could be stored locally and have a configurable TTL.
- **Historical Data / Sparklines**: Store historical data to be able to show trends over time, possibly with simple text-based sparklines in the `pretty` output format.
- **More Output Formats**: Add support for other formats like `tsv` or even image-based reports.
- **Plugin Manager**: A script to help users install and manage modules from a central repository.

We welcome contributions and ideas for the future of the project. If you have a suggestion, please open an issue on GitHub.
