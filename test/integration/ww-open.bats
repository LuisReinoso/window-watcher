#!/usr/bin/env bats

load ../test_helper

setup() {
    setup_stub_bin

    # Stub the common commands used by ww-open. Each test may override as needed.
    # We capture calls into files so we can assert which branch was taken.
    STUB_LOG="$BATS_TEST_TMPDIR/stub-log"
    : > "$STUB_LOG"

    cat > "$STUB_BIN/wmctrl" <<'EOF'
#!/usr/bin/env bash
echo "$WMCTRL_OUTPUT"
EOF
    chmod +x "$STUB_BIN/wmctrl"

    cat > "$STUB_BIN/xdg-settings" <<'EOF'
#!/usr/bin/env bash
echo "$XDG_SETTINGS_OUTPUT"
EOF
    chmod +x "$STUB_BIN/xdg-settings"

    # Recorder stubs for the browser commands and xdg-open
    for cmd in firefox chromium google-chrome chrome xdg-open; do
        cat > "$STUB_BIN/$cmd" <<EOF
#!/usr/bin/env bash
echo "$cmd \$*" >> "$STUB_LOG"
EOF
        chmod +x "$STUB_BIN/$cmd"
    done
}

teardown() {
    teardown_stub_bin
}

run_ww_open() {
    run "$PROJECT_DIR/ww-open" "$@"
}

@test "ww-open prints usage when called with no arguments" {
    run_ww_open
    assert_failure
    assert_output --partial "Usage: ww-open"
}

@test "ww-open uses xdg-open when a firefox window exists on the current workspace" {
    export WMCTRL_OUTPUT="* DG: 1x1
0x07000001  0 0    0    100  100  host Firefox.Firefox   Some Page"
    export XDG_SETTINGS_OUTPUT="firefox.desktop"

    # Force wmctrl -d to return workspace 0 active, wmctrl -lx to return a firefox window on ws 0
    cat > "$STUB_BIN/wmctrl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -d)  echo "0  * DG: 0x0  VP: N/A  WA: 0,0 0x0  main" ;;
    -lx) echo "0x07000001  0 Navigator.Firefox    host Firefox" ;;
esac
EOF
    chmod +x "$STUB_BIN/wmctrl"

    run_ww_open "https://example.com"
    assert_success
    run cat "$STUB_LOG"
    assert_output --partial "xdg-open https://example.com"
}

@test "ww-open opens a new firefox window when no browser exists on the current workspace" {
    cat > "$STUB_BIN/wmctrl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -d)  echo "0  * DG: 0x0  VP: N/A  WA: 0,0 0x0  main" ;;
    -lx) echo "0x00800004  0 Code.Code  host VS Code" ;;
esac
EOF
    chmod +x "$STUB_BIN/wmctrl"

    cat > "$STUB_BIN/xdg-settings" <<'EOF'
#!/usr/bin/env bash
echo "firefox.desktop"
EOF
    chmod +x "$STUB_BIN/xdg-settings"

    run_ww_open "dashboard.html"
    assert_success
    run cat "$STUB_LOG"
    assert_output --partial "firefox --new-window dashboard.html"
}

@test "ww-open opens a new google-chrome window when chrome is the default browser" {
    cat > "$STUB_BIN/wmctrl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -d)  echo "1  * DG: 0x0  VP: N/A  WA: 0,0 0x0  main" ;;
    -lx) echo "" ;;
esac
EOF
    chmod +x "$STUB_BIN/wmctrl"

    cat > "$STUB_BIN/xdg-settings" <<'EOF'
#!/usr/bin/env bash
echo "google-chrome.desktop"
EOF
    chmod +x "$STUB_BIN/xdg-settings"

    run_ww_open "https://example.com"
    assert_success
    run cat "$STUB_LOG"
    assert_output --partial "google-chrome --new-window https://example.com"
}

@test "ww-open opens a tab when browser exists on the current workspace with chrome" {
    cat > "$STUB_BIN/wmctrl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -d)  echo "2  * DG: 0x0  VP: N/A  WA: 0,0 0x0  main" ;;
    -lx) echo "0x05000004  2 google-chrome.Google-chrome  host Google Chrome" ;;
esac
EOF
    chmod +x "$STUB_BIN/wmctrl"

    run_ww_open "https://example.com"
    assert_success
    run cat "$STUB_LOG"
    assert_output --partial "xdg-open https://example.com"
}

@test "ww-open falls back to xdg-open when default browser is unknown" {
    cat > "$STUB_BIN/wmctrl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -d)  echo "0  * DG: 0x0  VP: N/A  WA: 0,0 0x0  main" ;;
    -lx) echo "" ;;
esac
EOF
    chmod +x "$STUB_BIN/wmctrl"

    cat > "$STUB_BIN/xdg-settings" <<'EOF'
#!/usr/bin/env bash
echo "brave-browser.desktop"
EOF
    chmod +x "$STUB_BIN/xdg-settings"

    run_ww_open "https://example.com"
    assert_success
    run cat "$STUB_LOG"
    assert_output --partial "xdg-open https://example.com"
}
