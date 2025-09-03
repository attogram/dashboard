#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We create a consistent config.sh for all dashboard integration tests.
  cat > config.sh <<'EOL'
# Test Configuration
HN_USER='pg'
GITHUB_USER='attogram'
REPOS=('base' '2048-lite')
DISCORD_SERVER_ID='1400382194509287426'
GITHUB_TOKEN=''
CRYPTO_WALLET_BTC='1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
CRYPTO_WALLET_ETH='0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae'
EOL
  tab=$(printf '\t')
}

teardown() {
  # This teardown function is run after each test.
  rm -f config.sh
}

@test "dashboard.sh should be executable" {
  [ -x "dashboard.sh" ]
}

@test "dashboard.sh --help should return 0" {
  run ./dashboard.sh --help
  [ "$status" -eq 0 ]
}

@test "dashboard.sh --help should show usage" {
  run ./dashboard.sh --help
  [ "${lines[0]}" = "Usage: dashboard.sh [options] [module]" ]
}

# --- Integration Tests for Aggregated Output ---

@test "integration: json output should be valid json" {
  run ./dashboard.sh --format json
  [ "$status" -eq 0 ]
  # Pipe the output to jq to validate it.
  # jq will exit with a non-zero status if the JSON is invalid.
  echo "$output" | jq -e . > /dev/null
}

@test "integration: xml output should contain root element and module data" {
  run ./dashboard.sh --format xml
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<\?xml version="1.0" encoding="UTF-8"\?><dashboard>.*</dashboard>$'
  echo "$clean_output" | grep -q -E '<hackernews><karma>[0-9]+</karma></hackernews>'
  echo "$clean_output" | grep -q -E '<github>.*<base>.*</base>.*</github>'
}

@test "integration: html output should contain root elements and module data" {
  run ./dashboard.sh --format html
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<!DOCTYPE html><html><head>.*</head><body>.*</body></html>$'
  echo "$clean_output" | grep -q -E '<h2>Hacker News</h2>'
  echo "$clean_output" | grep -q -E '<h2>GitHub Repositories</h2>'
}

@test "integration: csv output should contain headers and module data" {
  run ./dashboard.sh --format csv
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "module,key,value" ]
  echo "$output" | grep -q "hackernews,karma"
  echo "$output" | grep -q "github,base,stars"
}

@test "integration: tsv output should contain headers and module data" {
  run ./dashboard.sh --format tsv
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Date${tab}module${tab}name${tab}value" ]
  echo "$output" | grep -q "hackernews${tab}karma"
}

@test "integration: table output should gracefully fallback to tsv when column is missing" {
  run ./dashboard.sh --format table
  [ "$status" -eq 0 ]
  [[ "$output" == *"'column' command not found. Falling back to tsv format."* ]]
  [[ "$output" == *"Date${tab}module${tab}name${tab}value"* ]]
  echo "$output" | grep -q "hackernews"
  echo "$output" | grep -q "karma"
}

@test "integration: default output should be tsv" {
  run ./dashboard.sh
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Date${tab}module${tab}name${tab}value" ]
  echo "$output" | grep -q "hackernews${tab}karma"
}
