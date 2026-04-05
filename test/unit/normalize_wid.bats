#!/usr/bin/env bats

load ../test_helper

setup() {
    source_window_watcher
}

@test "normalize_wid pads a short hex id to 10 chars" {
    run normalize_wid "0x7e013c6"
    assert_success
    assert_output "0x07e013c6"
}

@test "normalize_wid leaves already-padded hex id unchanged" {
    run normalize_wid "0x07e013c6"
    assert_success
    assert_output "0x07e013c6"
}

@test "normalize_wid handles zero" {
    run normalize_wid "0x0"
    assert_success
    assert_output "0x00000000"
}

@test "normalize_wid handles a minimal hex value" {
    run normalize_wid "0x1"
    assert_success
    assert_output "0x00000001"
}

@test "normalize_wid handles a large hex value" {
    run normalize_wid "0xffffffff"
    assert_success
    assert_output "0xffffffff"
}
