# file zmux.sh
#!/usr/bin/env bash
set -e
#config=$(parse_config "~/.config/zmux/config.yaml")
command -v tmux >/dev/null 2>&1 || { echo >&2 "tmux is required but it's not installed. Aborting."; exit 1; }
command -v yq >/dev/null 2>&1 || { echo >&2 "yq is required but it's not installed. Aborting."; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config_parser.sh"
source "${SCRIPT_DIR}/session_manager.sh"
source "${SCRIPT_DIR}/utils.sh"

#CONFIG_FILE="${HOME}/.config/zmux/config.yaml"
CONFIG_FILE="./config.yaml"

main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: zmux <session_name>"
        list_sessions
        exit 1
    fi

    local session_name="$1"
    local config=$(parse_config "$CONFIG_FILE")
    
    if ! session_exists "$session_name"; then
        if session_config_exists "$config" "$session_name"; then
            create_session "$config" "$session_name"
        else
            echo "Session '$session_name' not found in configuration."
            exit 1
        fi
    fi

    # Attach to the session
    if [[ -z "$TMUX" ]]; then
        # Outside tmux, attach directly
        tmux attach-session -t "$session_name"
    else
        # Inside tmux, switch client
        tmux switch-client -t "$session_name"
    fi
}

list_sessions() {
    echo "Available sessions (open and configured):"

    # Parse the config to get session names
    local config=$(parse_config "$CONFIG_FILE")
    local configured_sessions=$(get_session_names "$config")

    # Get the list of currently running tmux sessions
    local open_sessions=$(tmux list-sessions -F "#S" 2>/dev/null)

    # Loop through each configured session
    echo "$configured_sessions" | while read -r session; do
        if echo "$open_sessions" | grep -q "^$session$"; then
            echo "  - $session (OPEN)"
        else
            echo "  - $session (NOT OPEN)"
        fi
    done

    # Also print sessions that are open in tmux but not listed in the config
    echo "$open_sessions" | while read -r open_session; do
        if ! echo "$configured_sessions" | grep -q "^$open_session$"; then
            echo "  - $open_session (OPEN, NOT CONFIGURED)"
        fi
    done
}

main "$@"
