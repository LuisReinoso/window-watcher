#!/usr/bin/env bats

load ../test_helper

setup() {
    source_window_watcher
}

@test "is_valid_ws accepts 0" {
    run is_valid_ws "0"
    assert_success
}

@test "is_valid_ws accepts positive integers" {
    run is_valid_ws "1"
    assert_success
    run is_valid_ws "9"
    assert_success
    run is_valid_ws "42"
    assert_success
}

@test "is_valid_ws rejects -1 (sticky)" {
    run is_valid_ws "-1"
    assert_failure
}

@test "is_valid_ws rejects empty string" {
    run is_valid_ws ""
    assert_failure
}

@test "is_valid_ws rejects non-numeric input" {
    run is_valid_ws "foo"
    assert_failure
}

@test "is_valid_ws rejects negative numbers other than -1" {
    run is_valid_ws "-5"
    assert_failure
}

@test "is_valid_ws rejects mixed alphanumeric" {
    run is_valid_ws "1a"
    assert_failure
}
