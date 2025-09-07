#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We create a consistent config.sh for all hackernews tests.
  mkdir -p config
  cat > config/config.sh <<'EOL'
# Test Configuration
HN_USER='pg'
EOL
  tab=$(printf '\t')
}

teardown() {
  # This teardown function is run after each test.
  rm -rf config
}

@test "hackernews module (plain)" {
  run ./modules/hackernews.sh plain
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Hacker News" ]
  [[ "${lines[1]}" =~ ^Karma:\ [0-9]+$ ]]
}

@test "hackernews module (pretty)" {
  run ./modules/hackernews.sh pretty
  [ "$status" -eq 0 ]
  # Using grep to strip ANSI codes before checking content
  [[ "$(echo ${lines[0]} | grep -o 'Hacker News')" = "Hacker News" ]]
  [[ "${lines[1]}" =~ ^Karma:\ [0-9]+$ ]]
}

@test "hackernews module (json)" {
  run ./modules/hackernews.sh json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^"hackernews":{"karma":[0-9]+}$'
}

@test "hackernews module (xml)" {
  run ./modules/hackernews.sh xml
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<hackernews><karma>[0-9]+</karma></hackernews>$'
}

@test "hackernews module (html)" {
  run ./modules/hackernews.sh html
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<h2>Hacker News</h2><ul><li>Karma: [0-9]+</li></ul>$'
}

@test "hackernews module (yaml)" {
  run ./modules/hackernews.sh yaml
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "hackernews:" ]
  [[ "${lines[1]}" =~ \ \ karma:\ [0-9]+ ]]
}

@test "hackernews module (csv)" {
  run ./modules/hackernews.sh csv
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z,hackernews,karma,pg,[0-9]+$ ]]
}

@test "hackernews module (markdown)" {
  run ./modules/hackernews.sh markdown
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "### Hacker News" ]
  [[ "${lines[1]}" =~ ^-\ Karma:\ [0-9]+$ ]]
}

@test "hackernews module (tsv)" {
  run ./modules/hackernews.sh tsv
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z${tab}hackernews${tab}karma${tab}pg${tab}[0-9]+$ ]]
}

@test "hackernews module requires a format" {
  run ./modules/hackernews.sh ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage: hackernews.sh <format>" ]]
}

@test "hackernews module rejects invalid format" {
  run ./modules/hackernews.sh "bogus"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Error: Unsupported format 'bogus'" ]]
}
