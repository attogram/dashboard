#!/usr/bin/env bash
#
# modules/crypto.sh
#
# Fetches crypto wallet balances using multiple providers.
#

# --- Configuration and Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="${SCRIPT_DIR}/../config/config.sh"
if [[ -f "$config_file" ]]; then
    # shellcheck source=../config/config.sh
    source "$config_file"
fi

# --- Input ---
format="$1"
if [[ -z "$format" ]]; then
    echo "Usage: ${0##*/} <format>" >&2
    exit 1
fi

# --- Data Fetching ---

# Function to format a raw balance string using its decimals value.
format_balance() {
    local balance_raw="$1"
    local decimals="$2"
    local len=${#balance_raw}
    shopt -s extglob
    if (( decimals == 0 )); then
        echo "$balance_raw"
        return
    fi
    local frac_part int_part
    if (( len <= decimals )); then
        int_part='0'
        frac_part=$(printf "%0*d" "$decimals" "$balance_raw")
    else
        int_part="${balance_raw:0:$((len - decimals))}"
        frac_part="${balance_raw:$((len - decimals))}"
    fi
    frac_part="${frac_part%%*(0)}"
    if [[ -z "$frac_part" ]]; then
        echo "$int_part"
    else
        echo "${int_part}.${frac_part}"
    fi
}

# Determines the provider for a given ticker.
get_provider() {
    local ticker=$1
    local provider_var="CRYPTO_${ticker}_PROVIDER"
    if [[ -n "${!provider_var}" ]]; then
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
    if ! command -v bitcoin-cli &> /dev/null; then return 1; fi
    local btc_info wallet_name balance display_name
    btc_info=$(bitcoin-cli getwalletinfo 2>/dev/null)
    if (( $? != 0 )); then return 1; fi
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
    if [[ -n "$BLOCKCYPHER_TOKEN" ]]; then
        api_url="${api_url}?token=${BLOCKCYPHER_TOKEN}"
    fi
    local response
    response=$(curl -s --connect-timeout 5 --max-time 10 "$api_url")
    if [[ -z "$response" || "$(echo "$response" | jq -r '.error // ""')" != "" ]]; then
        return 1
    fi
    local balance_raw decimals balance
    balance_raw=$(echo "$response" | jq -r '.balance')
    decimals=8
    if [[ "$ticker" == "ETH" ]]; then decimals=18; fi
    balance=$(format_balance "$balance_raw" "$decimals")
    echo "{\"chain\":\"${ticker}\",\"address\":\"${address}\",\"tokens\":[{\"symbol\":\"${ticker}\",\"balance\":\"${balance}\"}]}"
}

fetch_from_covalent() {
    local ticker=$1
    local address=$2
    if [[ -z "$COVALENT_API_KEY" ]]; then return 1; fi
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
    if [[ -z "$response" || "$(echo "$response" | jq -r '.error // ""')" != "" ]]; then
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
    if (( $(echo "$final_tokens" | jq '. | length') == 0 )); then return 1; fi
    echo "{\"chain\":\"${ticker}\",\"address\":\"${address}\",\"tokens\":${final_tokens}}"
}

# --- Main Dispatcher ---
wallet_vars=$(env | grep "^CRYPTO_WALLET_")
if [[ -z "$wallet_vars" ]]; then exit 0; fi

all_balances_json='[]'
while IFS= read -r line; do
    var_name=${line%%=*}
    address=${line#*=}
    address=${address//\"/}
    ticker=${var_name#CRYPTO_WALLET_}
    provider=$(get_provider "$ticker")
    wallet_json=''
    case "$provider" in
        local)
            if [[ "$ticker" == "BTC" ]]; then
                wallet_json=$(fetch_from_local_btc)
            fi
            ;;
        blockcypher)
            wallet_json=$(fetch_from_blockcypher "$ticker" "$address")
            ;;
        covalent)
            wallet_json=$(fetch_from_covalent "$ticker" "$address")
            ;;
    esac
    if [[ -n "$wallet_json" ]]; then
        all_balances_json=$(echo "$all_balances_json" | jq ". + [$wallet_json]")
    fi
done <<< "$wallet_vars"

if (( $(echo "$all_balances_json" | jq '. | length') == 0 )); then
    exit 0
fi
data=$all_balances_json

# --- Output Formatting ---
case "$format" in
    plain | pretty)
        echo 'Crypto Donations'
        echo "$data" | jq -r '.[] | "\(.chain) (\(.address))\n" + (.tokens[] | "  - \(.symbol): \(.balance)")'
        ;;
    json)
        echo "\"crypto\":${data}"
        ;;
    xml)
        echo '<crypto>'
        echo "$data" | jq -r '.[] | "  <wallet chain=\"\(.chain)\" address=\"\(.address)\">\n" + (.tokens[] | "    <token symbol=\"\(.symbol)\" balance=\"\(.balance)\"/>") + "\n  </wallet>"'
        echo '</crypto>'
        ;;
    html)
        echo '<h2>Crypto Donations</h2>'
        echo '<ul>'
        echo "$data" | jq -r '.[] | "  <li><b>\(.chain)</b> (<code>\(.address)</code>)<ul>" + (.tokens[] | "<li>\(.symbol): \(.balance)</li>") + "</ul></li>"'
        echo '</ul>'
        ;;
    yaml)
        echo 'crypto:'
        echo "$data" | jq -r '.[] | "  - chain: \(.chain)\n    address: \(.address)\n    tokens:\n" + (.tokens[] | "      - symbol: \(.symbol)\n        balance: \"\(.balance)\"")'
        ;;
    csv)
        echo 'module,chain,address,token_symbol,balance'
        echo "$data" | jq -r '.[] | . as $parent | .tokens[] | "crypto,\($parent.chain),\($parent.address),\(.symbol),\(.balance)"'
        ;;
        tsv)
            now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
            echo "$DATA" | jq -r --arg now "$now" '.[] | . as $parent | .tokens[] | [$now, "crypto", "crypto." + $parent.chain + "." + $parent.address + "." + .symbol, .balance] | @tsv'
            ;;
    markdown)
        echo '### Crypto Donations'
        echo "$data" | jq -r '.[] | "*   **\(.chain)** (`\(.address)`)\n" + (.tokens[] | "    *   **\(.symbol)**: \(.balance)")'
        ;;
    *)
        echo "Error: Unsupported format '$format'" >&2
        exit 1
        ;;
esac
