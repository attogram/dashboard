#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We ensure a valid config.sh is present for the modules to use.
  if [ ! -f "config/config.sh" ]; then
    cp config/config.dist.sh config/config.sh
  fi
  sed -i 's/HN_USER=".*"/HN_USER="pg"/' config/config.sh
  sed -i 's/GITHUB_USER=".*"/GITHUB_USER="attogram"/' config/config.sh
  sed -i 's/REPOS=(.*)/REPOS=("base" "2048-lite")/' config/config.sh
  # Ensure GITHUB_TOKEN is empty so the sponsors module is skipped
  sed -i 's/GITHUB_TOKEN=".*"/GITHUB_TOKEN=""/' config/config.sh
  # Add the discord server ID for testing
  sed -i 's/DISCORD_SERVER_ID=".*"/DISCORD_SERVER_ID="1400382194509287426"/' config/config.sh
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
