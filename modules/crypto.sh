#!/bin/bash
#
# modules/crypto.sh
#
# Fetches crypto wallet balances using the GoldRush (Covalent) API.
# This module checks for all environment variables prefixed with CRYPTO_WALLET_
# and retrieves their balances.
#

# --- Configuration and Setup ---

# Find and load the main config file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.sh"

if [ -f "$CONFIG_FILE" ]; then
    # The user might not have a config file, which is fine
    source "$CONFIG_FILE"
fi

# Check for required config variables
if [ -z "$GOLDRUSH_API_KEY" ]; then
    # Exit gracefully if the API key is not configured.
    # This module is optional.
    exit 0
fi

# --- Input ---

FORMAT="$1"
if [ -z "$FORMAT" ]; then
    echo "Usage: $(basename "$0") <format>" >&2
    exit 1
fi

# --- Data Fetching ---

# Function to map our simple tickers to the official GoldRush chain names
get_chain_name() {
    local ticker
    ticker=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$ticker" in
        BTC) echo "bitcoin" ;;
        ETH) echo "eth-mainnet" ;;
        MATIC) echo "matic-mainnet" ;;
        SOL) echo "solana-mainnet" ;;
        AVAX) echo "avalanche-mainnet" ;;
        ARB) echo "arbitrum-mainnet" ;;
        OP) echo "optimism-mainnet" ;;
        BASE) echo "base-mainnet" ;;
        FTM) echo "fantom-mainnet" ;;
        BNB) echo "bsc-mainnet" ;;
        *) echo "" ;;
    esac
}

# Function to format the raw balance string using the decimals value,
# since we don't have `bc` for floating point math.
format_balance() {
    local balance_raw="$1"
    local decimals="$2"
    local len=${#balance_raw}

    # Remove trailing zeros from fractional part later
    shopt -s extglob

    # If no decimals, it's a whole number
    if [ "$decimals" -eq 0 ]; then
        echo "$balance_raw"
        return
    fi

    local frac_part
    local int_part

    if [ "$len" -le "$decimals" ];
    then
        # It's a purely fractional number, pad with zeros
        int_part="0"
        frac_part=$(printf "%0*d" "$decimals" "$balance_raw")
    else
        # It's a mixed number
        int_part="${balance_raw:0:$((len - decimals))}"
        frac_part="${balance_raw:$((len - decimals))}"
    fi

    # Trim trailing zeros from the fractional part
    frac_part="${frac_part%%*(0)}"
    if [ -z "$frac_part" ]; then
        echo "$int_part"
    else
        echo "${int_part}.${frac_part}"
    fi
}

# Find all crypto wallet variables defined in the config
WALLET_VARS=$(env | grep "^CRYPTO_WALLET_")

# If no wallet variables are set, exit gracefully.
if [ -z "$WALLET_VARS" ]; then
    exit 0
fi

ALL_BALANCES_JSON="["
FIRST_WALLET=true
while IFS= read -r line; do
    VAR_NAME=$(echo "$line" | cut -d'=' -f1)
    ADDRESS=$(echo "$line" | cut -d'=' -f2- | tr -d '"')
    TICKER=$(echo "$VAR_NAME" | sed 's/CRYPTO_WALLET_//')

    CHAIN_NAME=$(get_chain_name "$TICKER")
    if [ -z "$CHAIN_NAME" ]; then continue; fi

    API_URL="https://api.covalenthq.com/v1/${CHAIN_NAME}/address/${ADDRESS}/balances_v2/?key=${GOLDRUSH_API_KEY}"
    API_RESPONSE=$(curl -s --connect-timeout 5 --max-time 10 "$API_URL")
    ERROR=$(echo "$API_RESPONSE" | jq -r '.error')

    if [ "$ERROR" != "null" ]; then continue; fi

    # Start building JSON for this wallet
    if [ "$FIRST_WALLET" = false ]; then ALL_BALANCES_JSON="${ALL_BALANCES_JSON},"; fi
    FIRST_WALLET=false
    ALL_BALANCES_JSON="${ALL_BALANCES_JSON}{\"chain\":\"${TICKER}\",\"address\":\"${ADDRESS}\",\"tokens\":["

    TOKENS_JSON=$(echo "$API_RESPONSE" | jq -c '.data.items[] | select(.balance != "0") | {symbol: .contract_ticker_symbol, balance: .balance, decimals: .contract_decimals}')

    FIRST_TOKEN=true
    while IFS= read -r token_line; do
        SYMBOL=$(echo "$token_line" | jq -r '.symbol')
        BALANCE_RAW=$(echo "$token_line" | jq -r '.balance')
        DECIMALS=$(echo "$token_line" | jq -r '.decimals')

        BALANCE=$(format_balance "$BALANCE_RAW" "$DECIMALS")

        if [ "$FIRST_TOKEN" = false ]; then ALL_BALANCES_JSON="${ALL_BALANCES_JSON},"; fi
        FIRST_TOKEN=false
        ALL_BALANCES_JSON="${ALL_BALANCES_JSON}{\"symbol\":\"${SYMBOL}\",\"balance\":\"${BALANCE}\"}"
    done <<< "$TOKENS_JSON"

    ALL_BALANCES_JSON="${ALL_BALANCES_JSON}]}"
done <<< "$WALLET_VARS"

ALL_BALANCES_JSON="${ALL_BALANCES_JSON}]"

# If we didn't find anything, exit gracefully
if [ "$ALL_BALANCES_JSON" = "[]" ] || [ "$ALL_BALANCES_JSON" = "[,]" ]; then
    exit 0
fi

# Pass the final JSON to the output formatting section
DATA=$ALL_BALANCES_JSON

# --- Output Formatting ---

case "$FORMAT" in
    plain | pretty)
        echo "Crypto Donations"
        echo "$DATA" | jq -r '.[] | "\(.chain) (\(.address))\n" + (.tokens[] | "  - \(.symbol): \(.balance)")'
        ;;

    json)
        # Output the raw JSON data, correctly formatted for the main script.
        echo "\"crypto\":${DATA}"
        ;;

    xml)
        echo "<crypto>"
        echo "$DATA" | jq -r '.[] | "  <wallet chain=\"\(.chain)\" address=\"\(.address)\">\n" + (.tokens[] | "    <token symbol=\"\(.symbol)\" balance=\"\(.balance)\"/>") + "\n  </wallet>"'
        echo "</crypto>"
        ;;

    html)
        echo "<h2>Crypto Donations</h2>"
        echo "<ul>"
        echo "$DATA" | jq -r '.[] | "  <li><b>\(.chain)</b> (<code>\(.address)</code>)<ul>" + (.tokens[] | "<li>\(.symbol): \(.balance)</li>") + "</ul></li>"'
        echo "</ul>"
        ;;

    yaml)
        echo "crypto:"
        echo "$DATA" | jq -r '.[] | "  - chain: \(.chain)\n    address: \(.address)\n    tokens:\n" + (.tokens[] | "      - symbol: \(.symbol)\n        balance: \"\(.balance)\"")'
        ;;

    csv)
        echo "module,chain,address,token_symbol,balance"
        echo "$DATA" | jq -r '.[] | . as $parent | .tokens[] | "crypto,\($parent.chain),\($parent.address),\(.symbol),\(.balance)"'
        ;;

    markdown)
        echo "### Crypto Donations"
        echo "$DATA" | jq -r '.[] | "*   **\(.chain)** (`\(.address)`)\n" + (.tokens[] | "    *   **\(.symbol)**: \(.balance)")'
        ;;

    *)
        echo "Error: Unsupported format '$FORMAT'" >&2
        exit 1
        ;;
esac
