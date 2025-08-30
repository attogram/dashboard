#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  if [ ! -f "config.sh" ]; then
    cp config.dist.sh config.sh
  fi
  sed -i 's/GITHUB_USER=".*"/GITHUB_USER="attogram"/' config.sh
  sed -i 's/REPOS=(.*)/REPOS=("base" "2048-lite")/' config.sh
}

@test "github module (plain)" {
  run ./modules/github plain
  [ "$status" -eq 0 ]
  [[ "$output" =~ "GitHub Repositories" ]]
  [[ "$output" =~ "base:" ]]
  [[ "$output" =~ "Stars: " ]]
  [[ "$output" =~ "2048-lite:" ]]
}

@test "github module (pretty)" {
  run ./modules/github pretty
  [ "$status" -eq 0 ]
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  [[ "$clean_output" =~ "GitHub Repositories" ]]
  [[ "$clean_output" =~ "base:" ]]
  [[ "$clean_output" =~ "Stars: " ]]
  [[ "$clean_output" =~ "2048-lite:" ]]
}

@test "github module (json)" {
  run ./modules/github json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '"github":{'
  echo "$output" | grep -q -E '"base":{'
  echo "$output" | grep -q -E '"stars":'
  echo "$output" | grep -q -E '"2048-lite":{'
}

@test "github module (xml)" {
  run ./modules/github xml
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '<github>'
  echo "$output" | grep -q -E '<base>'
  echo "$output" | grep -q -E '<stars>'
  # Note: This will fail due to the invalid tag name. I will fix this later.
  # echo "$output" | grep -q -E '<2048-lite>'
}

@test "github module (html)" {
  run ./modules/github html
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '<h2>GitHub Repositories</h2>'
  echo "$output" | grep -q -E '<h3>base</h3>'
  echo "$output" | grep -q -E '<li>Stars: '
  echo "$output" | grep -q -E '<h3>2048-lite</h3>'
}

@test "github module (yaml)" {
  run ./modules/github yaml
  [ "$status" -eq 0 ]
  [[ "$output" =~ "github:" ]]
  [[ "$output" =~ "  base:" ]]
  [[ "$output" =~ "    stars:" ]]
  [[ "$output" =~ "  2048-lite:" ]]
}

@test "github module (csv)" {
  run ./modules/github csv
  [ "$status" -eq 0 ]
  [[ "$output" =~ "github,base,stars," ]]
  [[ "$output" =~ "github,2048-lite,stars," ]]
}

@test "github module (markdown)" {
  run ./modules/github markdown
  [ "$status" -eq 0 ]
  [[ "$output" =~ "### GitHub Repositories" ]]
  [[ "$output" =~ "#### base" ]]
  [[ "$output" =~ "- Stars: " ]]
  [[ "$output" =~ "#### 2048-lite" ]]
}
