#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.

  # We ensure a valid config.sh is present for the modules to use.
  mkdir -p ../config
  cat > ../config/config.sh <<'EOL'
# Test Configuration
HN_USER='pg'
GITHUB_USER='attogram'
REPOS=('base' '2048-lite')
DISCORD_SERVER_ID='1400382194509287426'
GITHUB_TOKEN=''
CRYPTO_WALLET_BTC='1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
CRYPTO_WALLET_ETH='0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae'
EOL
}

teardown() {
  # This teardown function is run after each test.
  rm -f ../config/config.sh
}

@test "dashboard.sh should be executable" {
  [ -x "../dashboard.sh" ]
}

@test "dashboard.sh --help should return 0" {
  run ../dashboard.sh --help
  [ "$status" -eq 0 ]
}

@test "dashboard.sh --help should show usage" {
  run ../dashboard.sh --help
  [[ "${lines[0]}" =~ "Usage:" ]]
}

# --- Integration Tests for Aggregated Output ---

@test "integration: json output should be valid json" {
  run ../dashboard.sh --format json
  [ "$status" -eq 0 ]
  # Pipe the output to jq to validate it.
  # jq will exit with a non-zero status if the JSON is invalid.
  echo "$output" | jq -e . > /dev/null
}

@test "integration: xml output should contain root element and module data" {
  run ../dashboard.sh --format xml
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<\?xml version="1.0" encoding="UTF-8"\?><dashboard><timestamp>.*</timestamp>.*</dashboard>$'
  echo "$clean_output" | grep -q -E '<hackernews user="pg" url="https://news.ycombinator.com/user?id=pg"><karma>[0-9]+</karma></hackernews>'
  echo "$clean_output" | grep -q -E '<github user="attogram" url="https://github.com/attogram">.*<base>.*</base>.*</github>'
}

@test "integration: html output should contain root elements and module data" {
  run ../dashboard.sh --format html
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<!DOCTYPE html><html><head>.*</head><body><p>Report generated at: .*</p>.*</body></html>$'
  echo "$clean_output" | grep -q -E '<h2><a href="https://news.ycombinator.com/user?id=pg">Hacker News for pg</a></h2>'
  echo "$clean_output" | grep -q -E '<h2><a href="https://github.com/attogram">GitHub Repositories for attogram</a></h2>'
}

@test "integration: csv output should contain headers and module data" {
  run ../dashboard.sh --format csv
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "module,key,value" ]
  echo "$output" | grep -q "hackernews,karma"
  echo "$output" | grep -q "github,user,attogram"
}
