#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We create a consistent config.sh for all dashboard integration tests.
  mkdir -p config
  cat > config/config.sh <<'EOL'
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

@test "integration: default output should be to a file in ./reports" {
  run ./dashboard.sh
  [ "$status" -eq 0 ]
  [ -d "reports" ]
  # Find the created file
  report_file=$(find reports -type f -name "*.tsv")
  [ -n "$report_file" ]
  # Check content
  content=$(cat "$report_file")
  [[ "$content" == *"date${tab}module${tab}channels${tab}namespace${tab}value"* ]]
  [[ "$content" == *"hackernews${tab}karma${tab}pg"* ]]
  rm -r reports
}

@test "integration: -o option with a file path" {
  run ./dashboard.sh -o my_report.tsv
  [ "$status" -eq 0 ]
  [ -f "my_report.tsv" ]
  content=$(cat "my_report.tsv")
  [[ "$content" == *"date${tab}module${tab}channels${tab}namespace${tab}value"* ]]
  rm my_report.tsv
}

@test "integration: -o option with a directory path" {
  mkdir -p my_reports
  run ./dashboard.sh -o my_reports
  [ "$status" -eq 0 ]
  report_file=$(find my_reports -type f -name "*.tsv")
  [ -n "$report_file" ]
  content=$(cat "$report_file")
  [[ "$content" == *"date${tab}module${tab}channels${tab}namespace${tab}value"* ]]
  rm -r my_reports
}

teardown() {
  # This teardown function is run after each test.
  rm -rf config
  rm -rf reports
  rm -f my_report.tsv
  rm -rf my_reports
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
  echo "$output" | grep -q "Available modules:"
  echo "$output" | grep -q "crypto"
  echo "$output" | grep -q "discord"
  echo "$output" | grep -q "github"
  echo "$output" | grep -q "hackernews"
}

# --- Integration Tests for Aggregated Output ---

@test "integration: json output should be valid json" {
  run ./dashboard.sh --format json -o /dev/stdout
  [ "$status" -eq 0 ]
  # Pipe the output to jq to validate it.
  # jq will exit with a non-zero status if the JSON is invalid.
  echo "$output" | jq -e . > /dev/null
}

@test "integration: xml output should contain root element and module data" {
  run ./dashboard.sh --format xml -o /dev/stdout
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<\?xml version="1.0" encoding="UTF-8"\?><dashboard>.*</dashboard>$'
  echo "$clean_output" | grep -q -E '<hackernews><karma>[0-9]+</karma></hackernews>'
  echo "$clean_output" | grep -q -E '<github>.*<base>.*</base>.*</github>'
}

@test "integration: html output should contain root elements and module data" {
  run ./dashboard.sh --format html -o /dev/stdout
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<!DOCTYPE html><html><head>.*</head><body>.*</body></html>$'
  echo "$clean_output" | grep -q -E '<h2>Hacker News</h2>'
  echo "$clean_output" | grep -q -E '<h2>GitHub Repositories</h2>'
}

@test "integration: csv output should contain headers and module data" {
  run ./dashboard.sh --format csv -o /dev/stdout
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "date,module,channels,namespace,value" ]
  echo "$output" | grep -q "hackernews,karma,pg"
  echo "$output" | grep -q "github,stars,repo.attogram.base"
}

@test "integration: tsv output should contain headers and module data" {
  run ./dashboard.sh --format tsv -o /dev/stdout
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "date${tab}module${tab}channels${tab}namespace${tab}value" ]
  echo "$output" | grep -q "hackernews${tab}karma${tab}pg"
}

@test "integration: table output should be a pretty ascii table" {
  run ./dashboard.sh --format table -o /dev/stdout
  [ "$status" -eq 0 ]
  # Check for top border
  [[ "${lines[0]}" == "+-"* ]]
  # Check for header
  [[ "${lines[1]}" == *"| date"* ]]
  # Check for separator
  [[ "${lines[2]}" == "+-"* ]]
  # Check for data
  echo "$output" | grep -q "hackernews"
  echo "$output" | grep -q "karma"
  # Check for bottom border
  [[ "${lines[-1]}" == "+-"* ]]
}
