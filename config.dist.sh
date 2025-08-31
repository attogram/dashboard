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

# --- API Keys (Optional) ---

# (Optional) Your Covalent API Key. Required for the "covalent" provider.
# Get a key from: https://www.covalenthq.com/platform/
COVALENT_API_KEY=""

# (Optional) Your BlockCypher API Token. Not required for balance checks,
# but can be used to get higher rate limits.
# Get a token from: https://accounts.blockcypher.com/
BLOCKCYPHER_TOKEN=""


# --- Provider Configuration ---
# For each chain, specify a provider.
# Supported providers: "covalent", "blockcypher", "local" (BTC only).
# If a provider for a specific ticker is not set, the module will try them in a
# default order.
#
# Covalent: Supports many EVM chains. Requires COVALENT_API_KEY.
# BlockCypher: Supports BTC, ETH, LTC, DASH, DOGE. No API key needed for balance checks.
# local: Supports BTC via a local `bitcoind` node.

# Example Provider Configuration:
# CRYPTO_BTC_PROVIDER="local"
# CRYPTO_ETH_PROVIDER="blockcypher"
# CRYPTO_MATIC_PROVIDER="covalent"


# --- Wallet Addresses ---
# Add the wallet addresses you want to track below.
# The script will fetch balances for any variable starting with CRYPTO_WALLET_
#
# Format: CRYPTO_WALLET_<TICKER>="your_address"

CRYPTO_WALLET_BTC="your_bitcoin_address"
CRYPTO_WALLET_ETH="your_ethereum_address"
#CRYPTO_WALLET_LTC="your_litecoin_address"
#CRYPTO_WALLET_DOGE="your_dogecoin_address"
#CRYPTO_WALLET_DASH="your_dash_address"
#CRYPTO_WALLET_MATIC="your_polygon_address"
#CRYPTO_WALLET_AVAX="your_avalanche_address"
#CRYPTO_WALLET_ARB="your_arbitrum_address"
#CRYPTO_WALLET_OP="your_optimism_address"
#CRYPTO_WALLET_BASE="your_base_address"
#CRYPTO_WALLET_FTM="your_fantom_address"
#CRYPTO_WALLET_BNB="your_bnb_smart_chain_address"
