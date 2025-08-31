#!/usr/bin/env bats

setup() {
    # Mock for bitcoin-cli
    bitcoin-cli() {
        cat "test/mocks/bitcoin_cli_getwalletinfo.json"
    }
    export -f bitcoin-cli

    # Mock for curl
    curl() {
        if [[ "$1" == *"api.blockcypher.com"* ]]; then
            cat "test/mocks/blockcypher_btc.json"
        elif [[ "$1" == *"api.covalenthq.com"* ]]; then
            cat "test/mocks/crypto_eth.json"
        else
            echo "{\"error\":true, \"error_message\":\"Mock not found for this URL\"}" >&2
            return 1
        fi
    }
    export -f curl
}

teardown() {
    unset -f bitcoin-cli
    unset -f curl
}

@test "crypto: local btc provider" {
    output=$(env CRYPTO_BTC_PROVIDER="local" \
                   CRYPTO_WALLET_BTC="any_value" \
                   bash ../modules/crypto.sh plain)
    status=$?
    [ "$status" -eq 0 ]
    [[ "$output" == *"local node (my_local_wallet)"* ]]
    [[ "$output" == *"- BTC: 1.23"* ]]
}

@test "crypto: blockcypher btc provider" {
    output=$(env CRYPTO_BTC_PROVIDER="blockcypher" \
                   CRYPTO_WALLET_BTC="test_btc_address" \
                   bash ../modules/crypto.sh plain)
    status=$?
    [ "$status" -eq 0 ]
    [[ "$output" == *"BTC (test_btc_address)"* ]]
    [[ "$output" == *"- BTC: 0.5"* ]]
}

@test "crypto: covalent eth provider" {
    output=$(env CRYPTO_ETH_PROVIDER="covalent" \
                   COVALENT_API_KEY="test_key" \
                   CRYPTO_WALLET_ETH="test_eth_address" \
                   bash ../modules/crypto.sh plain)
    status=$?
    [ "$status" -eq 0 ]
    [[ "$output" == *"ETH (test_eth_address)"* ]]
    [[ "$output" == *"- ETH: 1.2345"* ]]
}

@test "crypto: exits gracefully if no wallet vars are provided" {
    output=$(bash ../modules/crypto.sh plain)
    status=$?
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
