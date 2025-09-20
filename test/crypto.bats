#!/usr/bin/env bats

setup() {
    MOCK_DIR="/tmp/bats_mocks_$$"
    mkdir -p "$MOCK_DIR"
    export PATH="$MOCK_DIR:$PATH"
    tab=$(printf '\t')

    # Mock for bitcoin-cli
    cat << 'EOF' > "$MOCK_DIR/bitcoin-cli"
#!/bin/bash
# Mock for bitcoin-cli returning a fixed balance
echo '{"walletname": "mock_wallet", "balance": 1.23}'
EOF
    chmod +x "$MOCK_DIR/bitcoin-cli"

    # Mock for curl
    cat << 'EOF' > "$MOCK_DIR/curl"
#!/bin/bash
# The crypto.sh script calls curl with several arguments, e.g.
# curl -s --connect-timeout 5 --max-time 10 "$api_url"
# The URL is the last argument. This mock finds it.
while [[ $# -gt 1 ]]; do
    shift
done
url="$1"

if [[ "$url" == *"api.blockcypher.com"* ]]; then
    echo '{"address": "test_btc_address", "balance": 12345678}' # 0.12345678 BTC
elif [[ "$url" == *"api.covalenthq.com"* ]]; then
    echo '{"data": {"items": [{"balance": "1234000000000000000", "contract_ticker_symbol": "ETH", "contract_decimals": 18}]}}' # 1.234 ETH
else
    # In case of an unexpected URL, exit with an error to fail the test
    >&2 echo "Mock curl called with unexpected URL: $url"
    exit 1
fi
EOF
    chmod +x "$MOCK_DIR/curl"
}

teardown() {
    rm -rf "/tmp/bats_mocks_$$"
}

@test "crypto: local btc provider" {
    run env CRYPTO_BTC_PROVIDER="local" \
            CRYPTO_WALLET_BTC="any_value" \
            bash modules/crypto.sh
    [ "$status" -eq 0 ]
    [[ "$output" =~ .*${tab}crypto${tab}balance${tab}crypto.BTC.local\ node\ \(mock_wallet\).BTC${tab}1.23$ ]]
}

@test "crypto: blockcypher btc provider" {
    run env CRYPTO_BTC_PROVIDER="blockcypher" \
            CRYPTO_WALLET_BTC="test_btc_address" \
            bash modules/crypto.sh
    [ "$status" -eq 0 ]
    echo "Blockcypher Output: $output"
    [[ "$output" =~ .*${tab}crypto${tab}balance${tab}crypto.BTC.test_btc_address.BTC${tab}0.12345678$ ]]
}

@test "crypto: covalent eth provider" {
    run env CRYPTO_ETH_PROVIDER="covalent" \
            COVALENT_API_KEY="test_key" \
            CRYPTO_WALLET_ETH="test_eth_address" \
            bash modules/crypto.sh
    [ "$status" -eq 0 ]
    echo "Covalent Output: $output"
    [[ "$output" =~ .*${tab}crypto${tab}balance${tab}crypto.ETH.test_eth_address.ETH${tab}1.234$ ]]
}

@test "crypto: exits gracefully if no wallet vars are provided" {
    run bash modules/crypto.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
