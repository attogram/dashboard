#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We create a consistent config.sh for all github tests.
  mkdir -p config
  cat > config/config.sh <<'EOL'
# Test Configuration
GITHUB_USER='attogram'
REPOS=('base' '2048-lite')
EOL
  tab=$(printf '\t')
}

teardown() {
  # This teardown function is run after each test.
  rm -f config/config.sh
}

@test "github module produces valid tsv" {
  run ./modules/github.sh
  [ "$status" -eq 0 ]

  # Should be 6 metrics per repo * 2 repos = 12 lines
  [ "${#lines[@]}" -eq 12 ]

  # Check that each line has 5 tab-separated columns
  for line in "${lines[@]}"; do
    num_columns=$(echo "$line" | awk -F'\t' '{print NF}')
    [ "$num_columns" -eq 5 ]
  done

  # Check that the output contains the expected repo names
  echo "$output" | grep -q "repo.attogram.base"
  echo "$output" | grep -q "repo.attogram.2048-lite"

  # Check that the output contains the expected metric names
  echo "$output" | grep -q "stars"
  echo "$output" | grep -q "forks"
  echo "$output" | grep -q "open_issues"
  echo "$output" | grep -q "watchers"
  echo "$output" | grep -q "open_prs"
  echo "$output" | grep -q "closed_prs"
}
