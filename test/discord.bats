#!/usr/bin/env bats

setup() {
  # This setup function is run before each test.
  # We create a consistent config.sh for all discord tests.
  mkdir -p config
  cat > config/config.sh <<'EOL'
# Test Configuration
DISCORD_SERVER_ID='123456789' # This ID is mocked
EOL
  tab=$(printf '\t')

  # Mock curl to return a fixed response for the Discord API
  MOCK_DIR="/tmp/bats_mocks_$$"
  mkdir -p "$MOCK_DIR"
  export PATH="$MOCK_DIR:$PATH"
  cat << 'EOF' > "$MOCK_DIR/curl"
#!/bin/bash
echo '{"presence_count": 123}'
EOF
  chmod +x "$MOCK_DIR/curl"
}

teardown() {
  # This teardown function is run after each test.
  rm -f config/config.sh
  rm -rf "/tmp/bats_mocks_$$"
}

@test "discord module produces valid tsv" {
  run ./modules/discord.sh
  [ "$status" -eq 0 ]

  # Should be 1 line of output
  [ "${#lines[@]}" -eq 1 ]

  # Check that the line has 5 tab-separated columns
  num_columns=$(echo "$output" | awk -F'\t' '{print NF}')
  [ "$num_columns" -eq 5 ]

  # Check the content of the line
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z${tab}discord${tab}online${tab}discord${tab}123$ ]]
}

@test "discord module exits gracefully with no server id" {
  # Overwrite config to have no DISCORD_SERVER_ID
  echo "" > config/config.sh
  run ./modules/discord.sh
  [ "$status" -eq 0 ]
  [ -z "$output" ] # Expect no output
}
