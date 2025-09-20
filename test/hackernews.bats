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
  rm -f config/config.sh
}

@test "hackernews module produces valid tsv" {
  run ./modules/hackernews.sh
  [ "$status" -eq 0 ]

  # Should be 1 line of output
  [ "${#lines[@]}" -eq 1 ]

  # Check that the line has 5 tab-separated columns
  num_columns=$(echo "$output" | awk -F'\t' '{print NF}')
  [ "$num_columns" -eq 5 ]

  # Check the content of the line
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z${tab}hackernews${tab}karma${tab}pg${tab}[0-9]+$ ]]
}

@test "hackernews module exits gracefully if no user is set" {
  # Overwrite config to have no HN_USER
  echo "" > config/config.sh
  run ./modules/hackernews.sh
  [ "$status" -eq 0 ]
  [ -z "$output" ] # Expect no output
}
