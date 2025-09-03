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
  rm -rf config
}

@test "github module (plain)" {
  run ./modules/github.sh plain
  [ "$status" -eq 0 ]
  [[ "$output" =~ "GitHub Repositories" ]]
  [[ "$output" =~ "base:" ]]
  [[ "$output" =~ "Stars: " ]]
  [[ "$output" =~ "2048-lite:" ]]
}

@test "github module (pretty)" {
  run ./modules/github.sh pretty
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$clean_output" =~ "GitHub Repositories" ]]
  [[ "$clean_output" =~ "base:" ]]
  [[ "$clean_output" =~ "Stars: " ]]
  [[ "$clean_output" =~ "2048-lite:" ]]
}

@test "github module (json)" {
  run ./modules/github.sh json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '"github":{'
  echo "$output" | grep -q -E '"base":{'
  echo "$output" | grep -q -E '"stars":'
  echo "$output" | grep -q -E '"2048-lite":{'
}

@test "github module (xml)" {
  run ./modules/github.sh xml
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '<github>'
  echo "$output" | grep -q -E '<base>'
  echo "$output" | grep -q -E '<stars>'
  echo "$output" | grep -q -E '<_2048_lite>'
}

@test "github module (html)" {
  run ./modules/github.sh html
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '<h2>GitHub Repositories</h2>'
  echo "$output" | grep -q -E '<h3>base</h3>'
  echo "$output" | grep -q -E '<li>Stars: '
  echo "$output" | grep -q -E '<h3>2048-lite</h3>'
}

@test "github module (yaml)" {
  run ./modules/github.sh yaml
  [ "$status" -eq 0 ]
  [[ "$output" =~ "github:" ]]
  [[ "$output" =~ "  base:" ]]
  [[ "$output" =~ "    stars:" ]]
  [[ "$output" =~ "  2048-lite:" ]]
}

@test "github module (csv)" {
  run ./modules/github.sh csv
  [ "$status" -eq 0 ]
  [[ "$output" =~ "github,base,stars," ]]
  [[ "$output" =~ "github,2048-lite,stars," ]]
}

@test "github module (markdown)" {
  run ./modules/github.sh markdown
  [ "$status" -eq 0 ]
  [[ "$output" =~ "### GitHub Repositories" ]]
  [[ "$output" =~ "#### base" ]]
  [[ "$output" =~ "- Stars: " ]]
  [[ "$output" =~ "#### 2048-lite" ]]
}

@test "github module (tsv)" {
  run ./modules/github.sh tsv
  [ "$status" -eq 0 ]
  for line in "${lines[@]}"; do
    [[ "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z${tab}github${tab}.*${tab}([0-9]+|null)$ ]]
  done
  echo "$output" | grep -q "base.stars"
  echo "$output" | grep -q "2048-lite.stars"
}
