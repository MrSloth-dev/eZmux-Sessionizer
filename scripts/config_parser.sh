#!/usr/bin/env bash

# Function to parse YAML config file with flattening
parse_config() {
  local config_file="$1"
  if [[ ! -f "$config_file" ]]; then
    echo "Config file not found: $config_file" >&2
    return 1
  fi

  # Parse YAML into a single line with flattened key-value pairs using yq
  flat_config=$(yq eval -o=props "$config_file")

  echo "$flat_config"
}

# Function to get all session names from the config
get_session_names() {
  local config="$1"
  echo "$config" | grep '^sessions\.' | cut -d'.' -f2 | sort | uniq
}

# Function to check if a session exists in the config
session_config_exists() {
  local config="$1"
  local session_name="$2"
  echo "$config" | grep -q "^sessions\.${session_name}\."
}

# Function to get a specific session's configuration
get_session_config() {
  local config="$1"
  local session_name="$2"
  echo "$config" | grep "^sessions\.${session_name}\." | sed "s/^sessions\.${session_name}\.//"
}

# Function to get the root directory for a session
get_session_root() {
  local config="$1"
  local session_name="$2"
  echo "$config" | grep "^sessions\.${session_name}\.root=" | cut -d'=' -f2 | tr -d '"'
}

# Function to get all window configurations for a session
get_session_windows() {
  local config="$1"
  local session_name="$2"
  echo "$config" | grep "^sessions\.${session_name}\.windows\." | sed "s/^sessions\.${session_name}\.windows\.//"
}

# Function to get a specific window's name
get_window_name() {
  local window_config="$1"
  echo "$window_config" | grep "\.name=" | cut -d'=' -f2 | tr -d '"'
}

# Function to get a specific window's command
get_window_command() {
  local window_config="$1"
  echo "$window_config" | grep "\.command=" | cut -d'=' -f2 | tr -d '"'
}

# Example usage:
# config=$(parse_config "/path/to/config.yaml")
# session_names=$(get_session_names "$config")
# session_config=$(get_session_config "$config" "example")
# root_dir=$(get_session_root "$config" "example")
# windows=$(get_session_windows "$config" "example")
