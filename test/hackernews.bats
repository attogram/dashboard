#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  mkdir -p ../config
  cat > ../config/config.sh <<'EOL'
# Test Configuration
HN_USER='pg'
EOL
}

teardown() {
  # This teardown function is run after each test.
  rm -f ../config/config.sh
}

@test "hackernews module (plain)" {
  run ../modules/hackernews.sh plain
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "Hacker News for pg" ]]
  [[ "${lines[1]}" =~ ^Karma:\ [0-9]+$ ]]
}

@test "hackernews module (pretty)" {
  run ../modules/hackernews.sh pretty
  [ "$status" -eq 0 ]
  # Using grep to strip ANSI codes before checking content
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$clean_output" =~ "Hacker News for pg" ]]
  [[ "${lines[1]}" =~ ^Karma:\ [0-9]+$ ]]
}

@test "hackernews module (json)" {
  run ../modules/hackernews.sh json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^"hackernews":{"user":"pg","url":".*","karma":[0-9]+}$'
}

@test "hackernews module (xml)" {
  run ../modules/hackernews.sh xml
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<hackernews user="pg" url=".*"><karma>[0-9]+</karma></hackernews>$'
}

@test "hackernews module (html)" {
  run ../modules/hackernews.sh html
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<h2><a href=".*">Hacker News for pg</a></h2><ul><li>Karma: [0-9]+</li></ul>$'
}

@test "hackernews module (yaml)" {
  run ../modules/hackernews.sh yaml
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "hackernews:" ]
  [[ "${lines[1]}" =~ \ \ user:\ pg ]]
}

@test "hackernews module (csv)" {
  run ../modules/hackernews.sh csv
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "hackernews,user,pg"
}

@test "hackernews module (markdown)" {
  run ../modules/hackernews.sh markdown
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "### [Hacker News for pg]" ]]
  [[ "${lines[1]}" =~ ^-\ Karma:\ [0-9]+$ ]]
}

@test "hackernews module requires a format" {
  run ../modules/hackernews.sh ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "hackernews module rejects invalid format" {
  run ../modules/hackernews.sh "bogus"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Error: Unsupported format 'bogus'" ]]
}
