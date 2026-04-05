# Shared test helper: loads bats libraries and sources the script under test

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$TEST_DIR/.." && pwd)"

load "$TEST_DIR/bats-support/load"
load "$TEST_DIR/bats-assert/load"

# Source the script under test without running main()
source_window_watcher() {
    # Prevent the script from running main() by setting BASH_SOURCE trick
    # The script uses [[ "${BASH_SOURCE[0]}" == "$0" ]] guard, which is false when sourced
    source "$PROJECT_DIR/window-watcher.sh"
}

# Create a temporary bin dir and prepend it to PATH so stub commands take precedence
setup_stub_bin() {
    STUB_BIN="$(mktemp -d)"
    export PATH="$STUB_BIN:$PATH"
}

teardown_stub_bin() {
    [[ -n "$STUB_BIN" && -d "$STUB_BIN" ]] && rm -rf "$STUB_BIN"
}

# Create a stub command that prints the given output
stub_command() {
    local cmd="$1"
    local output="$2"
    cat > "$STUB_BIN/$cmd" <<EOF
#!/usr/bin/env bash
cat <<'STUB_OUTPUT'
$output
STUB_OUTPUT
EOF
    chmod +x "$STUB_BIN/$cmd"
}
