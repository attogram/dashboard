#!/usr/bin/env bash
#
# modules/crypto.sh
#
# Fetches crypto wallet balances using multiple providers and outputs them in TSV format.
#

# --- Configuration and Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# --- Data Fetching ---

# Function to format a raw balance string using its decimals value.
format_balance() {
    local balance_raw="$1"
    local decimals="$2"
    local len=${#balance_raw}
    shopt -s extglob
    if [ "$decimals" -eq 0 ]; then
        echo "$balance_raw"
        return
    fi
    local frac_part int_part
    if [ "$len" -le "$decimals" ]; then
        int_part='0'
        frac_part=$(printf "%0*d" "$decimals" "$balance_raw")
    else
        int_part="${balance_raw:0:$((len - decimals))}"
        frac_part="${balance_raw:$((len - decimals))}"
    fi
    frac_part="${frac_part%%*(0)}"
    if [ -z "$frac_part" ]; then
        echo "$int_part"
    else
        echo "${int_part}.${frac_part}"
    fi
}

# Determines the provider for a given ticker.
get_provider() {
    local ticker=$1
    local provider_var="CRYPTO_${ticker}_PROVIDER"
    if [ -n "${!provider_var}" ]; then
        echo "${!provider_var}"
    else
        case "$ticker" in
            BTC|ETH|LTC|DOGE|DASH) echo 'blockcypher' ;;
            *) echo 'covalent' ;;
        esac
    fi
}

# --- Provider Implementations ---

fetch_from_local_btc() {
    if ! command -v bitcoin-cli &> /dev/null; then
        echo "[ERROR] bitcoin-cli not found. Please install Bitcoin Core and ensure bitcoin-cli is in your PATH." >&2
        return 1
    fi
    local btc_info
    btc_info=$(bitcoin-cli getwalletinfo 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "[ERROR] bitcoin-cli command failed. Please ensure your Bitcoin node is running and configured correctly." >&2
        return 1
    fi
    local wallet_name balance display_name
    wallet_name=$(echo "$btc_info" | jq -r '.walletname')
    balance=$(echo "$btc_info" | jq -r '.balance')
    display_name="local node ($wallet_name)"
    echo "{\"chain\":\"BTC\",\"address\":\"${display_name}\",\"tokens\":[{\"symbol\":\"BTC\",\"balance\":\"${balance}\"}]}"
}

fetch_from_blockcypher() {
    local ticker=$1
    local address=$2
    local chain_map
    case "$ticker" in
        BTC) chain_map='btc/main' ;;
        ETH) chain_map='eth/main' ;;
        LTC) chain_map='ltc/main' ;;
        DOGE) chain_map='doge/main' ;;
        DASH) chain_map='dash/main' ;;
        *) return 1 ;;
    esac
    local api_url="https://api.blockcypher.com/v1/${chain_map}/addrs/${address}/balance"
    if [ -n "$BLOCKCYPHER_TOKEN" ]; then
        api_url="${api_url}?token=${BLOCKCYPHER_TOKEN}"
    fi
    local response
    response=$(curl -s --connect-timeout 5 --max-time 10 "$api_url")
    if [ -z "$response" ] || [ "$(echo "$response" | jq -r '.error // ""')" != "" ]; then
        return 1
    fi
    local balance_raw decimals balance
    balance_raw=$(echo "$response" | jq -r '.balance')
    decimals=8
    if [ "$ticker" = "ETH" ]; then decimals=18; fi
    balance=$(format_balance "$balance_raw" "$decimals")
    echo "{\"chain\":\"${ticker}\",\"address\":\"${address}\",\"tokens\":[{\"symbol\":\"${ticker}\",\"balance\":\"${balance}\"}]}"
}

fetch_from_covalent() {
    local ticker=$1
    local address=$2
    if [ -z "$COVALENT_API_KEY" ]; then return 1; fi
    local chain_name
    case "$ticker" in
        ETH) chain_name='eth-mainnet' ;;
        MATIC) chain_name='matic-mainnet' ;;
        AVAX) chain_name='avalanche-mainnet' ;;
        *) return 1 ;;
    esac
    local api_url="https://api.covalenthq.com/v1/${chain_name}/address/${address}/balances_v2/?key=${COVALENT_API_KEY}"
    local response
    response=$(curl -s --connect-timeout 5 --max-time 10 "$api_url")
    if [ -z "$response" ] || [ "$(echo "$response" | jq -r '.error // ""')" != "" ]; then
        return 1
    fi
    local tokens_json
    tokens_json=$(echo "$response" | jq -c '[.data.items[] | select(.balance != "0") | {symbol: .contract_ticker_symbol, balance: .balance, decimals: .contract_decimals}]')
    local final_tokens="[]"
    while IFS= read -r token_line; do
        local symbol balance_raw decimals balance
        symbol=$(echo "$token_line" | jq -r '.symbol')
        balance_raw=$(echo "$token_line" | jq -r '.balance')
        decimals=$(echo "$token_line" | jq -r '.decimals')
        balance=$(format_balance "$balance_raw" "$decimals")
        final_tokens=$(echo "$final_tokens" | jq ". + [{\"symbol\":\"${symbol}\",\"balance\":\"${balance}\"}]")
    done <<< "$(echo "$tokens_json" | jq -c '.[]')"
    if [ "$(echo "$final_tokens" | jq '. | length')" -eq 0 ]; then return 1; fi
    echo "{\"chain\":\"${ticker}\",\"address\":\"${address}\",\"tokens\":${final_tokens}}"
}

# --- Main Dispatcher ---
WALLET_VARS=$(env | grep "^CRYPTO_WALLET_")
if [ -z "$WALLET_VARS" ]; then exit 0; fi

ALL_BALANCES_JSON='[]'
while IFS= read -r line; do
    VAR_NAME=$(echo "$line" | cut -d'=' -f1)
    ADDRESS=$(echo "$line" | cut -d'=' -f2- | tr -d '"')
    TICKER=$(echo "$VAR_NAME" | sed 's/CRYPTO_WALLET_//')
    PROVIDER=$(get_provider "$TICKER")
    wallet_json=''
    case "$PROVIDER" in
        local)
            if [ "$TICKER" = "BTC" ]; then
                wallet_json=$(fetch_from_local_btc)
            fi
            ;;
        blockcypher)
            wallet_json=$(fetch_from_blockcypher "$TICKER" "$ADDRESS")
            ;;
        covalent)
            wallet_json=$(fetch_from_covalent "$TICKER" "$ADDRESS")
            ;;
    esac
    if [ -n "$wallet_json" ]; then
        ALL_BALANCES_JSON=$(echo "$ALL_BALANCES_JSON" | jq ". + [$wallet_json]")
    fi
done <<< "$WALLET_VARS"

if [ "$(echo "$ALL_BALANCES_JSON" | jq '. | length')" -eq 0 ]; then
    exit 0
fi
DATA=$ALL_BALANCES_JSON

# --- Output Formatting ---
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "$DATA" | jq -r --arg now "$now" '.[] | . as $parent | .tokens[] | [$now, "crypto", "balance", "crypto." + $parent.chain + "." + $parent.address + "." + .symbol, .balance] | @tsv'
