#!/bin/bash
#
# Example configuration file for dashboard.
#
# Copy this file to config.sh and edit it to your needs.
#
# --- GitHub -------------------------------------------------------------------
#
# Your GitHub username.
# Required by: modules/github.sh
#
GITHUB_USER=""

#
# An array of your repository names to fetch stats for.
# Example: REPOS=("repo1" "repo2")
# Required by: modules/github.sh
#
REPOS=()

#
# Your GitHub Personal Access Token (PAT).
# Required for modules/github-sponsors.sh
# Optional for modules/github.sh (to avoid rate limiting).
# Create a token at: https://github.com/settings/tokens
#
GITHUB_TOKEN=""


# --- Hacker News --------------------------------------------------------------
#
# Your Hacker News username.
# Required by: modules/hackernews.sh
#
HN_USER=""


# --- Discord ------------------------------------------------------------------
#
# Your Discord server ID.
# To get this, right-click your server icon in Discord and select "Copy Server ID".
# You may need to enable Developer Mode in your Discord settings first.
# Required by: modules/discord.sh
#
DISCORD_SERVER_ID=""

#
# Note on Discord Stats:
# The current implementation only fetches the number of online users via the
# server's public widget. To get more detailed stats like total member count,
# you would need to create a Discord Bot, give it the "Server Members Intent",
# and use its token to make authenticated API calls. This would require
# modifying the modules/discord.sh script.
#


# --- Crypto Donations ---------------------------------------------------------
#
# Your cryptocurrency wallet addresses.
# The script will try to fetch balances for any address you provide here.
# The variable name should be `CRYPTO_WALLET_{TICKER}`.
#
# Examples:
# CRYPTO_WALLET_BTC="bc1q..."
# CRYPTO_WALLET_ETH="0x..."
# CRYPTO_WALLET_LTC="ltc1q..."
# CRYPTO_WALLET_DOGE="D..."
# CRYPTO_WALLET_DASH="X..."

#
# You can also specify a provider for a given ticker.
# By default, BTC, ETH, LTC, DOGE, and DASH use 'blockcypher'.
# Other EVM-compatible chains can use 'covalent'.
#
# Examples:
# CRYPTO_MATIC_PROVIDER="covalent"
# CRYPTO_WALLET_MATIC="0x..."
# CRYPTO_AVAX_PROVIDER="covalent"
# CRYPTO_WALLET_AVAX="0x..."

#
# API Keys for crypto providers (optional, but recommended).
#
BLOCKCYPHER_TOKEN=""
COVALENT_API_KEY=""
