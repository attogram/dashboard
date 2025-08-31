# --------------------------------------------------
# dashboard Configuration
# --------------------------------------------------

# Your Hacker News username
HN_USER="your_username_here"

# Your GitHub username
GITHUB_USER="your_username_here"

# A space-separated list of your key GitHub repositories to track.
REPOS=("your-repo-1" "your-repo-2")

# (Optional) Your Discord Server ID for tracking online members.
DISCORD_SERVER_ID=""

# --------------------------------------------------
# Optional & Advanced Configuration
# --------------------------------------------------

# GitHub Personal Access Token (PAT)
#
# Required for the 'github-sponsors' module.
# Create a token here: https://github.com/settings/tokens/new
# The token needs the 'read:user' scope.
GITHUB_TOKEN=""

# --------------------------------------------------
# Crypto Donations Module
# --------------------------------------------------

# (Required) Your GoldRush API Key from Covalent.
# Get a free key from: https://www.covalenthq.com/platform/
GOLDRUSH_API_KEY=""

# Your crypto wallet addresses.
# The dashboard will fetch balances for any variable that starts with CRYPTO_WALLET_
# The format is CRYPTO_WALLET_<CHAIN_TICKER>="your_address"
#
# Supported chain tickers can be found in the GoldRush API documentation.
# Examples for popular chains:
#
# CRYPTO_WALLET_BTC="your_bitcoin_address"
# CRYPTO_WALLET_ETH="your_ethereum_address"
# CRYPTO_WALLET_MATIC="your_polygon_address"
# CRYPTO_WALLET_SOL="your_solana_address"
# CRYPTO_WALLET_AVAX="your_avalanche_address"
# CRYPTO_WALLET_ARB="your_arbitrum_address"
# CRYPTO_WALLET_OP="your_optimism_address"
# CRYPTO_WALLET_BASE="your_base_address"
# CRYPTO_WALLET_FTM="your_fantom_address"
# CRYPTO_WALLET_BNB="your_bnb_smart_chain_address"
