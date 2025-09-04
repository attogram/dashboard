#
# Dashboard Configuration
#
# Copy this file to config.sh and edit it with your own settings.
#

# --- Main Module Settings -----------------------------------------------------

# Discord server ID (optional)
# To enable, find your server ID and enable the public widget.
DISCORD_SERVER_ID=''

# Hacker News username
HN_USER='your_username'

# GitHub username
GITHUB_USER='your_username'

# GitHub Personal Access Token (optional)
# Provides higher API rate limits for the 'github' module and is required
# for the 'github-sponsors' module.
# Scope: read:user
GITHUB_TOKEN=''

# GitHub repositories to track
REPOS=('your_repo_1' 'your_repo_2')


# --- Crypto Module Settings (optional) ----------------------------------------

# The key should be CRYPTO_WALLET_<TICKER>
CRYPTO_WALLET_BTC=''
CRYPTO_WALLET_ETH=''
