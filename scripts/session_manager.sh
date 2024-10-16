# file session_manager.sh
#!/usr/bin/env bash

# Check if a tmux session exists
session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

# Create a new tmux session based on the configuration
create_session() {
    local config="$1"
    local session_name="$2"
    
    local root_dir=$(get_session_root "$config" "$session_name")
    local windows=$(get_session_windows "$config" "$session_name")

    # Start a new session
    tmux new-session -d -s "$session_name" -c "$root_dir"

    local window_index=0
    echo "$windows" | while read -r window_config; do
        local window_name=$(get_window_name "$window_config")
        local window_command=$(get_window_command "$window_config")

        if [[ $window_index -eq 0 ]]; then
            # Rename the first window
            tmux rename-window -t "${session_name}:0" "$window_name"
        else
            # Create a new window
            tmux new-window -t "${session_name}:$window_index" -n "$window_name" -c "$root_dir"
        fi

        # If a command is specified, run it in the window
        if [[ -n "$window_command" ]]; then
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
