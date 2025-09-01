#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We create a consistent config.sh for all discord tests.
  cat > config.sh <<'EOL'
# Test Configuration
DISCORD_SERVER_ID='1400382194509287426'
EOL
}

teardown() {
  # This teardown function is run after each test.
  rm -f config.sh
}

@test "discord module (plain)" {
  run ./modules/discord.sh plain
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Discord" ]
  [[ "${lines[1]}" =~ ^Online:\ [0-9]+$ ]]
}

@test "discord module (pretty)" {
  run ./modules/discord.sh pretty
  [ "$status" -eq 0 ]
  [[ "$(echo ${lines[0]} | grep -o 'Discord')" = "Discord" ]]
  [[ "${lines[1]}" =~ ^Online:\ [0-9]+$ ]]
}

@test "discord module (json)" {
  run ./modules/discord.sh json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^"discord":{"online":[0-9]+}$'
}

@test "discord module (xml)" {
  run ./modules/discord.sh xml
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<discord><online>[0-9]+</online></discord>$'
}

@test "discord module (html)" {
  run ./modules/discord.sh html
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -E '^<h2>Discord</h2><ul><li>Online: [0-9]+</li></ul>$'
}

@test "discord module (yaml)" {
  run ./modules/discord.sh yaml
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "discord:" ]
  [[ "${lines[1]}" =~ \ \ online:\ [0-9]+ ]]
}

@test "discord module (csv)" {
  run ./modules/discord.sh csv
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^discord,online,[0-9]+$ ]]
}

@test "discord module (markdown)" {
  run ./modules/discord.sh markdown
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "### Discord" ]
  [[ "${lines[1]}" =~ ^-\ Online:\ [0-9]+$ ]]
}

@test "discord module with no server id" {
  # Overwrite the config.sh created by setup()
  cat > config.sh <<'EOL'
# Test Configuration
DISCORD_SERVER_ID=''
EOL
  run ./modules/discord.sh plain
  [ "$status" -eq 0 ]
  [ -z "$output" ] # Should produce no output
}
