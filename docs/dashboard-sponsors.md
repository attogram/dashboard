# GitHub Sponsors Module

The `github-sponsors` module fetches and displays the total number of sponsors you have on GitHub.

## How it Works

This module uses the official GitHub GraphQL API to retrieve your sponsor count. Unlike the other modules that use the public REST API, the GraphQL API requires authentication to access this information.

## Configuration

To use this module, you must provide a GitHub Personal Access Token (PAT) in the `GITHUB_TOKEN` variable in your `config.sh` file.

### Creating a `GITHUB_TOKEN`

1.  Go to the [Personal access tokens](https://github.com/settings/tokens) page on GitHub.
2.  Click "Generate new token" and select "Generate new token (classic)".
3.  Give your token a descriptive name, such as "dashboard-script".
4.  Set the expiration for the token.
5.  Under "Select scopes", check the box for `read:user`. This will grant the necessary permissions to read your user profile data, including your sponsors.
6.  Click "Generate token" at the bottom of the page.
7.  **Important**: Copy the generated token immediately. You will not be able to see it again.
8.  Paste the token into the `GITHUB_TOKEN` variable in your `config.sh` file.

```bash
# Example
GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

If the `GITHUB_TOKEN` is not provided or is invalid, the module will be skipped or will report an error, and it will not be included in the report.
