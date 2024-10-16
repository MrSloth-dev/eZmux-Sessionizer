#!/bin/bash

# Function to flatten YAML data
parse_config() {
  local data="$1"
  local flattened_data

  for key in "${!data[@]}"; do
    if [[ "${data[$key]}" =~ ^\{.*\}$ ]]; then
      for subkey in "${!data[$key][@]}"; do
        flattened_data["${key}.${subkey}"]=$(flatten_yaml "${data[$key][$subkey]}")
      done
    else
      flattened_data["$key"]="${data[$key]}"
    fi
  done

  echo "${flattened_data[@]}"
}

# Load YAML data
yaml_data=$(yq -o=props ./config.yaml)

# Flatten the YAML data
flattened_yaml=$(parse_config "$yaml_data")

# Print the flattened YAML data
for key in "${!flattened_yaml[@]}"; do
  echo "$key: ${flattened_yaml[$key]}"
done
