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
DISCORD_SERVER_ID='100382194509287426' # Invalid ID to test graceful exit
GITHUB_TOKEN=''
CRYPTO_WALLET_BTC='1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
EOL
  tab=$(printf '\t')
}

teardown() {
  # This teardown function is run after each test.
  rm -f config/config.sh
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
  echo "$output" | grep -q "Usage: dashboard.sh \[options\] \[module\]"
  echo "$output" | grep -q -- "-o, --overview <name>"
  echo "$output" | grep -q "Available modules:"
  echo "$output" | grep -q "Available overviews:"
}

# --- Integration Tests for Centralized Output Formatting ---

@test "integration: json output should be valid json" {
  run ./dashboard.sh -f json
  [ "$status" -eq 0 ]
  echo "--- JSON Output from Test ---"
  echo "$output"
  echo "-----------------------------"
  # Pipe the output to jq to validate it is a valid JSON array.
  echo "$output" | jq -e '. | type == "array"' > /dev/null
  echo "$output" | jq -e '.[0] | has("date") and has("module") and has("value")' > /dev/null
}

@test "bugfix: json output should have correct numeric types" {
  run ./dashboard.sh -f json
  [ "$status" -eq 0 ]
  # Check that a known numeric value is a number, not a string
  github_stars_value=$(echo "$output" | jq '.[] | select(.module == "github" and .channels == "stars" and .namespace == "repo.attogram.base") | .value')
  [ "$(jq 'type' <<< "$github_stars_value")" = '"number"' ]

  # Check that a known numeric value from another module is also a number
  hackernews_karma_value=$(echo "$output" | jq '.[] | select(.module == "hackernews") | .value')
  [ "$(jq 'type' <<< "$hackernews_karma_value")" = '"number"' ]
}

@test "integration: xml output should contain root element and metric data" {
  run ./dashboard.sh -f xml
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<\?xml version="1.0" encoding="UTF-8"\?><dashboard>.*</dashboard>$'
  echo "$clean_output" | grep -q -E '<metric><date>.*</date><module>hackernews</module>.*</metric>'
  echo "$clean_output" | grep -q -E '<metric><date>.*</date><module>github</module>.*</metric>'
}

@test "integration: html output should contain a table with data" {
  run ./dashboard.sh -f html
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | tr -d '\n\r')
  echo "$clean_output" | grep -q -E '^<!DOCTYPE html><html><head>.*</head><body><table>.*</table></body></html>$'
  echo "$clean_output" | grep -q -E '<tr><th>Date</th><th>Module</th>'
  echo "$clean_output" | grep -q -E '<tr><td>.*</td><td>hackernews</td>'
}

@test "integration: csv output should contain headers and module data" {
  run ./dashboard.sh -f csv
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "date,module,channels,namespace,value" ]
  echo "$output" | grep -q "hackernews,karma,pg"
  echo "$output" | grep -q "github,stars,repo.attogram.base"
}

@test "integration: tsv output should contain headers and module data" {
  run ./dashboard.sh -f tsv
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "date${tab}module${tab}channels${tab}namespace${tab}value" ]
  echo "$output" | grep -q "hackernews${tab}karma${tab}pg"
}

@test "integration: table output should be a pretty ascii table" {
  run ./dashboard.sh -f table
  [ "$status" -eq 0 ]
  # Check for top border
  [[ "${lines[0]}" == "+-"* ]]
  # Check for header
  [[ "${lines[1]}" == *"| date"* ]]
  # Check for separator
  [[ "${lines[2]}" == "+-"* ]]
  # Check for data
  echo "$output" | grep -q "hackernews"
  # Check for bottom border
  [[ "${lines[-1]}" == "+-"* ]]
}
