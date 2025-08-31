#!/usr/bin/env bats

setup() {

    # Create a mock for curl
    curl() {
        if [[ "$1" == *"bitcoin"* ]]; then
            cat "$BATS_TEST_DIRNAME/mocks/crypto_btc.json"
        elif [[ "$1" == *"eth-mainnet"* ]]; then
            cat "$BATS_TEST_DIRNAME/mocks/crypto_eth.json"
        else
            # Return an error for any other URL to make sure tests are specific
            echo "{\"error\":true, \"error_message\":\"Mock not found for this URL\"}" >&2
            return 1
        fi
    }
    export -f curl
}

teardown() {
    # Unset the mock curl function
    unset -f curl
}

@test "crypto: outputs in plain format" {
    run env GOLDRUSH_API_KEY="test_api_key" \
        CRYPTO_WALLET_BTC="test_btc_address" \
        CRYPTO_WALLET_ETH="test_eth_address" \
        bash ./modules/crypto.sh plain
    [ "$status" -eq 0 ]
    [[ "$output" == *"Crypto Donations"* ]]
    [[ "$output" == *"BTC (test_btc_address)"* ]]
    [[ "$output" == *"- BTC: 0.5"* ]]
    [[ "$output" == *"ETH (test_eth_address)"* ]]
    [[ "$output" == *"- ETH: 1.2345"* ]]
    [[ "$output" == *"- USDC: 50.123456"* ]]
}

@test "crypto: outputs in json format" {
    run env GOLDRUSH_API_KEY="test_api_key" \
        CRYPTO_WALLET_BTC="test_btc_address" \
        CRYPTO_WALLET_ETH="test_eth_address" \
        bash ./modules/crypto.sh json
    [ "$status" -eq 0 ]
    # Use jq to validate the JSON structure and content
    echo "$output" | jq -e '
        .crypto[0].chain == "BTC" and
        .crypto[0].tokens[0].symbol == "BTC" and
        .crypto[0].tokens[0].balance == "0.5" and
        .crypto[1].chain == "ETH" and
        .crypto[1].tokens[0].symbol == "ETH" and
        .crypto[1].tokens[0].balance == "1.2345" and
        .crypto[1].tokens[1].symbol == "USDC" and
        .crypto[1].tokens[1].balance == "50.123456"
    '
}

@test "crypto: exits gracefully if no API key is provided" {
    unset GOLDRUSH_API_KEY
    run bash -c "./modules/crypto.sh plain"
    [ "$status" -eq 0 ]
    [ -z "$output" ] # Expect no output
}

@test "crypto: exits gracefully if no wallet addresses are provided" {
    unset CRYPTO_WALLET_BTC
    unset CRYPTO_WALLET_ETH
    run env GOLDRUSH_API_KEY="test_api_key" bash ./modules/crypto.sh plain
    [ "$status" -eq 0 ]
    [ -z "$output" ] # Expect no output
}
