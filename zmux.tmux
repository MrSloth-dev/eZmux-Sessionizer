#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config_parser.sh"
source "${SCRIPT_DIR}/session_manager.sh"
source "${SCRIPT_DIR}/utils.sh"

CONFIG_FILE="${HOME}/.config/zmux/config.yaml"

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
            local fuzzy_match=$(fuzzy_find_session "$config" "$session_name")
            if [[ -n "$fuzzy_match" ]]; then
                echo "Session '$session_name' not found. Did you mean '$fuzzy_match'?"
                read -p "Create session '$fuzzy_match'? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    create_session "$config" "$fuzzy_match"
                    session_name="$fuzzy_match"
                else
                    exit 1
                fi
            else
                echo "Session '$session_name' not found and no similar sessions exist."
                exit 1
            fi
        fi
    fi

    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

list_sessions() {
    echo "Available sessions:"
    local config=$(parse_config "$CONFIG_FILE")
    get_session_names "$config" | while read -r session; do
        echo "  - $session"
    done
}

main "$@"
