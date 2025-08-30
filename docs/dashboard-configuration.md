# Configuration

The Dashboard project is configured via a single shell script, `config.sh`. To get started, you should copy the template file `config.dist.sh` to `config.sh` and edit it with your own settings.

The `config.sh` file is ignored by git, so your personal information and API keys will not be committed to the repository.

## Main Configuration

These are the primary variables you will need to set to use the dashboard.

### `HN_USER`

- **Description**: Your username on Hacker News.
- **Used by**: `hackernews` module.
- **Example**: `HN_USER="your_username_here"`

### `GITHUB_USER`

- **Description**: Your username on GitHub.
- **Used by**: `github` module.
- **Example**: `GITHUB_USER="your_username_here"`

### `REPOS`

- **Description**: A space-separated list of your key GitHub repositories to track. These should be the names of the repositories, without your username.
- **Used by**: `github` module.
- **Example**: `REPOS=("my-cool-project" "another-repo")`

### `DISCORD_SERVER_ID`

- **Description**: (Optional) The ID of your Discord server for tracking online members. The server must have the public widget enabled.
- **Used by**: `discord` module.
- **Example**: `DISCORD_SERVER_ID="123456789012345678"`

## Advanced Configuration

These variables are for modules that require more sensitive information, like API tokens.

### `GITHUB_TOKEN`

- **Description**: (Optional) A GitHub Personal Access Token (PAT). This is required for the `github-sponsors` module to fetch your sponsor count.
- **How to get**:
  1.  Go to [github.com/settings/tokens/new](https://github.com/settings/tokens/new).
  2.  Create a new "classic" token.
  3.  Give the token a name (e.g., "dashboard").
  4.  Grant it the `read:user` scope.
  5.  Copy the generated token and paste it here.
- **Used by**: `github-sponsors` module.
- **Example**: `GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"`
