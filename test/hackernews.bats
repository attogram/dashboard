#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We ensure a valid config.sh is present for the module to use.
  if [ ! -f "config.sh" ]; then
    cp config.dist.sh config.sh
  fi
  sed -i 's/HN_USER=".*"/HN_USER="pg"/' config.sh
}

@test "hackernews module (plain)" {
  run ./modules/hackernews plain
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Hacker News" ]
  [[ "${lines[1]}" =~ ^Karma:\ [0-9]+$ ]]
}

@test "hackernews module (pretty)" {
  run ./modules/hackernews pretty
  [ "$status" -eq 0 ]
  # Using grep to strip ANSI codes before checking content
  [[ "$(echo ${lines[0]} | grep -o 'Hacker News')" = "Hacker News" ]]
  [[ "${lines[1]}" =~ ^Karma:\ [0-9]+$ ]]
}

@test "hackernews module (json)" {
  run ./modules/hackernews json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^"hackernews":{"karma":[0-9]+}$'
}

@test "hackernews module (xml)" {
  run ./modules/hackernews xml
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<hackernews><karma>[0-9]+</karma></hackernews>$'
}

@test "hackernews module (html)" {
  run ./modules/hackernews html
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<h2>Hacker News</h2><ul><li>Karma: [0-9]+</li></ul>$'
}

@test "hackernews module (yaml)" {
  run ./modules/hackernews yaml
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "hackernews:" ]
  [[ "${lines[1]}" =~ \ \ karma:\ [0-9]+ ]]
}

@test "hackernews module (csv)" {
  run ./modules/hackernews csv
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^hackernews,karma,[0-9]+$ ]]
}

@test "hackernews module (markdown)" {
  run ./modules/hackernews markdown
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "### Hacker News" ]
  [[ "${lines[1]}" =~ ^-\ Karma:\ [0-9]+$ ]]
}

@test "hackernews module requires a format" {
  run ./modules/hackernews ""
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage: hackernews <format>" ]]
}

@test "hackernews module rejects invalid format" {
  run ./modules/hackernews "bogus"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Error: Unsupported format 'bogus'" ]]
}
