#!/usr/bin/env bash
# window-watcher.sh — reactive via xprop, zero CPU when idle
# Moves new windows to the workspace where they were launched from

set -o pipefail

# --- Configuration -----------------------------------------------------------

# Load user config from config.sh (next to the script, or from the project dir).
# The config file sets WATCH_CLASSES and any other overrides.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${WINDOW_WATCHER_CONFIG:-$SCRIPT_DIR/config.sh}"

WATCH_CLASSES=()

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Set DEBUG=1 to enable verbose logging
DEBUG="${DEBUG:-0}"

# --- Helpers ------------------------------------------------------------------

log()   { echo "[window-watcher] $*"; }
debug() { [[ "$DEBUG" == "1" ]] && echo "[window-watcher:debug] $*"; }

normalize_wid() {
    printf "0x%08x" "$1" 2>/dev/null
}

get_window_class() {
    xprop -id "$1" WM_CLASS 2>/dev/null \
        | grep -oi '"[^"]*"' | tr -d '"' | tr '[:upper:]' '[:lower:]' | tr '\n' ' ' \
        || true
}

is_watched() {
    local wclass="$1"
    for cls in "${WATCH_CLASSES[@]}"; do
        [[ "$wclass" == *"$cls"* ]] && return 0
    done
    return 1
}

# A workspace id is valid if it's a non-negative integer. -1 means "sticky"
# (on all workspaces) and must never be used as a move target, otherwise
# window-watcher would make every watched window sticky.
is_valid_ws() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# --- Focus tracker ------------------------------------------------------------
# Runs in the background. Tracks which workspace the user was on before
# the most recent focus change, so handle_new_window knows where to place
# new windows. External activation (e.g. clicking a URL) is handled by
# ww-open, which brings the window back after the browser opens it.

track_focus() {
    local prev_ws=""
    local curr_ws=""

    xprop -root -spy _NET_ACTIVE_WINDOW 2>/dev/null | while read -r line; do
        local raw_wid
        raw_wid=$(echo "$line" | grep -oP '0x[0-9a-f]+' | tail -1)
        [[ -z "$raw_wid" ]] && continue

        local focused_wid
        focused_wid=$(normalize_wid "$raw_wid")

        local win_ws
        win_ws=$(wmctrl -lp | awk -v w="$focused_wid" '$1 == w {print $2; exit}')

        # Ignore sticky windows (WS -1) — they would poison the state file
        # and make every subsequent watched window sticky.
        is_valid_ws "$win_ws" || continue

        prev_ws="$curr_ws"
        curr_ws="$win_ws"

        [[ -n "$prev_ws" ]] && is_valid_ws "$prev_ws" && echo "$prev_ws" > "$STATE_FILE"
        debug "focus changed: prev_ws=$prev_ws curr_ws=$curr_ws"
    done
}

# --- Window handler -----------------------------------------------------------

handle_new_window() {
    local wid
    wid=$(normalize_wid "$1")

    # Wait for WM_CLASS to be set (retry quickly to minimize visual blink)
    local wclass="" retries=0
    while [[ -z "$wclass" || "$wclass" == " " ]] && [[ $retries -lt 10 ]]; do
        wclass=$(get_window_class "$wid")
        ((retries++))
        [[ -z "$wclass" || "$wclass" == " " ]] && sleep 0.03
    done

    debug "new window $wid class='$wclass'"

    is_watched "$wclass" || return

    local current_ws target_ws
    current_ws=$(wmctrl -lp | awk -v w="$wid" '$1 == w {print $2; exit}')
    target_ws=$(cat "$STATE_FILE" 2>/dev/null)

    if ! is_valid_ws "$target_ws"; then
        target_ws=$(wmctrl -d | awk '/\*/ {print $1}')
        debug "$wid no valid focus state, fallback to active ws=$target_ws"
    fi

    # Never move windows to a sticky/invalid workspace
    if ! is_valid_ws "$target_ws"; then
        debug "$wid no valid target workspace, skipping move"
        return
    fi

    debug "$wid current_ws=$current_ws target_ws=$target_ws"

    if [[ "$current_ws" != "$target_ws" ]]; then
        log "$wid ($wclass) WS $current_ws -> WS $target_ws"
        wmctrl -ir "$wid" -t "$target_ws"
    fi
}

# --- Main ---------------------------------------------------------------------

main() {
    # Auto-detect DISPLAY if not set (e.g. when running under systemd)
    if [[ -z "$DISPLAY" ]]; then
        DISPLAY=$(w -h "$USER" 2>/dev/null | awk '/:[0-9]/ {print $3; exit}')
        export DISPLAY
    fi

    if [[ -z "$DISPLAY" ]]; then
        echo "[window-watcher] error: could not detect DISPLAY — is an X11 session running?"
        exit 1
    fi

    STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/window-watcher"
    STATE_FILE="$STATE_DIR/focus-state"
    mkdir -p "$STATE_DIR"

    cleanup() {
        [[ -n "$TRACKER_PID" ]] && kill "$TRACKER_PID" 2>/dev/null
        rm -rf "$STATE_DIR"
    }
    trap cleanup EXIT INT TERM

    log "started (PID $$, DISPLAY=$DISPLAY)"

    # Start focus tracker
    track_focus &
    TRACKER_PID=$!

    # Snapshot current windows so we don't process existing ones
    local KNOWN_WIDS=""
    for raw_wid in $(xprop -root _NET_CLIENT_LIST 2>/dev/null | grep -oP '0x[0-9a-f]+'); do
        KNOWN_WIDS+="$(normalize_wid "$raw_wid") "
    done

    # React to window list changes
    xprop -root -spy _NET_CLIENT_LIST 2>/dev/null | while read -r line; do
        local current_wids=""
        for raw_wid in $(echo "$line" | grep -oP '0x[0-9a-f]+'); do
            current_wids+="$(normalize_wid "$raw_wid") "
        done

        for wid in $current_wids; do
            if [[ "$KNOWN_WIDS" != *"$wid"* ]]; then
                debug "detected new window: $wid"
                handle_new_window "$wid"
            fi
        done

        KNOWN_WIDS="$current_wids"
    done
}

# Only run main when executed directly (not when sourced for tests)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
