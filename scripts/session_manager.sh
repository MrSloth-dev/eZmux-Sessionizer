# file session_manager.sh
#!/usr/bin/env bash

# Check if a tmux session exists
session_exists() {
    if tmux has-session -t "$1" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

get_session_start_index() {
    local config="$1"
    local session_name="$2"
    local start_index=$(echo "$config" | grep "^sessions\.${session_name}\.start_index=" | cut -d'=' -f2)
    
    if [[ -z "$start_index" ]]; then
        start_index=1  # Default to 0 if not specified
    fi
    echo "$start_index"
}
# Create a new tmux session based on the configuration
create_session() {
    local config="$1"
    local session_name="$2"

    local root_dir=$(get_session_root "$config" "$session_name")
    local windows=$(get_session_windows "$config" "$session_name")
    local start_index=$(get_session_start_index "$config" "$session_name")

    echo "Debug: root_dir = $root_dir"
    echo "Debug: start_index = $start_index"
    echo "Debug: Windows configuration:"
    echo "$windows"

    # Start a new session
    tmux new-session -d -s "$session_name" -c "$root_dir"

    local window_index=$start_index
    echo "$windows" | while read -r window_config; do
        echo "Debug: Processing window config: $window_config"
        local window_name=$(echo "$window_config" | grep '\.name=' | cut -d'=' -f2 | tr -d '"')
        local window_command=$(echo "$window_config" | grep '\.command=' | cut -d'=' -f2 | tr -d '"')

        echo "Debug: window_name = $window_name"
        echo "Debug: window_command = $window_command"

        if [[ $window_index -eq $start_index ]]; then
            echo "Debug: Renaming first window to $window_name"
            tmux rename-window -t "${session_name}:$window_index" "$window_name"
        else
            echo "Debug: Creating new window $window_name"
            tmux new-window -t "${session_name}:$window_index" -n "$window_name" -c "$root_dir"
        fi

        if [[ -n "$window_command" ]]; then
            echo "Debug: Sending command to window: $window_command"
            tmux send-keys -t "${session_name}:$window_index" "$window_command" C-m
        fi

        ((window_index++))
    done

    echo "Session '$session_name' created."
}

# Switch to an existing session or create a new one
switch_or_create_session() {
    local config="$1"
    local session_name="$2"

    if session_exists "$session_name"; then
        echo "Switching to existing session '$session_name'."
        if [[ -z "$TMUX" ]]; then
            tmux attach-session -t "$session_name"
        else
            tmux switch-client -t "$session_name"
        fi
    else
        echo "Creating new session '$session_name'."
        create_session "$config" "$session_name"
        if [[ -z "$TMUX" ]]; then
            tmux attach-session -t "$session_name"
        else
            tmux switch-client -t "$session_name"
        fi
    fi
}

# List all existing tmux sessions
list_sessions() {
    tmux list-sessions -F "#S" 2>/dev/null
}

# Kill a specific tmux session
kill_session() {
    local session_name="$1"
    if session_exists "$session_name"; then
        tmux kill-session -t "$session_name"
        echo "Session '$session_name' killed."
    else
        echo "Session '$session_name' does not exist."
    fi
}

# Rename an existing tmux session
rename_session() {
    local old_name="$1"
    local new_name="$2"
    if session_exists "$old_name"; then
        tmux rename-session -t "$old_name" "$new_name"
        echo "Session renamed from '$old_name' to '$new_name'."
    else
        echo "Session '$old_name' does not exist."
    fi
}
