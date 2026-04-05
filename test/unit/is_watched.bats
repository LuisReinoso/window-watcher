#!/usr/bin/env bats

load ../test_helper

setup() {
    source_window_watcher
    # Test-local watch list (script default is empty)
    WATCH_CLASSES=("alpha" "beta-app" "gamma")
}

@test "is_watched matches a class containing a watched substring" {
    run is_watched "alpha alpha "
    assert_success
}

@test "is_watched matches when the substring appears in the second class field" {
    run is_watched "instance alpha_alpha "
    assert_success
}

@test "is_watched matches a hyphenated substring" {
    run is_watched "beta-app beta-app "
    assert_success
}

@test "is_watched matches a substring embedded in a longer path" {
    run is_watched "gamma (/home/user/.config/gamma/profile 2) gamma "
    assert_success
}

@test "is_watched rejects an unrelated class" {
    run is_watched "delta delta "
    assert_failure
}

@test "is_watched rejects a class that does not contain any watched substring" {
    run is_watched "editor editor "
    assert_failure
}

@test "is_watched rejects an empty class" {
    run is_watched ""
    assert_failure
}

@test "is_watched rejects when WATCH_CLASSES is empty" {
    WATCH_CLASSES=()
    run is_watched "alpha alpha "
    assert_failure
}
