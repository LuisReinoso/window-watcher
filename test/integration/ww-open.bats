#!/usr/bin/env bats

load ../test_helper

setup() {
    setup_stub_bin

    STUB_LOG="$BATS_TEST_TMPDIR/stub-log"
    : > "$STUB_LOG"

    # Default stubs
    cat > "$STUB_BIN/xdg-settings" <<'EOF'
#!/usr/bin/env bash
echo "firefox.desktop"
EOF
    chmod +x "$STUB_BIN/xdg-settings"

    # Recorder stubs for browser commands
    for cmd in firefox chromium google-chrome xdg-open; do
        cat > "$STUB_BIN/$cmd" <<OUTER
#!/usr/bin/env bash
echo "$cmd \$*" >> "$STUB_LOG"
OUTER
        chmod +x "$STUB_BIN/$cmd"
    done

    # Stub sleep so tests don't actually wait
    cat > "$STUB_BIN/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$STUB_BIN/sleep"

    # Stub xprop (used in the background bring-back logic)
    cat > "$STUB_BIN/xprop" <<'EOF'
#!/usr/bin/env bash
echo "_NET_ACTIVE_WINDOW(WINDOW): window id # 0x00000000"
EOF
    chmod +x "$STUB_BIN/xprop"

    # Default wmctrl: no browser on any workspace
    cat > "$STUB_BIN/wmctrl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    -d)  echo "0  * DG: 0x0  VP: N/A  WA: 0,0 0x0  main" ;;
    -lx) echo "" ;;
    -lp) echo "" ;;
    *)   ;;
esac
EOF
    chmod +x "$STUB_BIN/wmctrl"

    # Config with BROWSER_CMD set
    export WINDOW_WATCHER_CONFIG="$BATS_TEST_TMPDIR/config.sh"
    echo 'BROWSER_CMD="firefox"' > "$WINDOW_WATCHER_CONFIG"

    # Isolate dedup cache per test
    export XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/runtime"
    mkdir -p "$XDG_RUNTIME_DIR"
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

@test "ww-open uses BROWSER_CMD to open URL" {
    run_ww_open "https://example.com"
    assert_success
    # Wait for background process
    sleep 0.1
    run cat "$STUB_LOG"
    assert_output --partial "firefox https://example.com"
}

@test "ww-open auto-detects browser when BROWSER_CMD is not set" {
    echo '' > "$WINDOW_WATCHER_CONFIG"

    cat > "$STUB_BIN/xdg-settings" <<'EOF'
#!/usr/bin/env bash
echo "chromium.desktop"
EOF
    chmod +x "$STUB_BIN/xdg-settings"

    run_ww_open "https://example.com"
    assert_success
    sleep 0.1
    run cat "$STUB_LOG"
    assert_output --partial "chromium https://example.com"
}

@test "ww-open auto-detects google-chrome as browser" {
    echo '' > "$WINDOW_WATCHER_CONFIG"

    cat > "$STUB_BIN/xdg-settings" <<'EOF'
#!/usr/bin/env bash
echo "google-chrome.desktop"
EOF
    chmod +x "$STUB_BIN/xdg-settings"

    run_ww_open "https://example.com"
    assert_success
    sleep 0.1
    run cat "$STUB_LOG"
    assert_output --partial "google-chrome https://example.com"
}

@test "ww-open passes the URL argument correctly" {
    run_ww_open "http://localhost:3000/dashboard"
    assert_success
    sleep 0.1
    run cat "$STUB_LOG"
    assert_output --partial "firefox http://localhost:3000/dashboard"
}

@test "ww-open dedups rapid duplicate invocations for the same URL" {
    run_ww_open "https://example.com"
    assert_success
    run_ww_open "https://example.com"
    assert_success
    sleep 0.1
    # Only one browser invocation should be recorded
    run bash -c "grep -c 'firefox https://example.com' '$STUB_LOG'"
    assert_output "1"
}

@test "ww-open does not dedup different URLs" {
    run_ww_open "https://example.com"
    assert_success
    run_ww_open "https://other.com"
    assert_success
    sleep 0.1
    run cat "$STUB_LOG"
    assert_output --partial "firefox https://example.com"
    assert_output --partial "firefox https://other.com"
}
