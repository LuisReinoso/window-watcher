#!/usr/bin/env bats

load ../test_helper

setup() {
    setup_stub_bin
    source_window_watcher
}

teardown() {
    teardown_stub_bin
}

@test "get_window_class parses xprop WM_CLASS output with two values" {
    stub_command xprop 'WM_CLASS(STRING) = "Instance", "ClassName"'
    run get_window_class "0x07e013c6"
    assert_success
    assert_output "instance classname "
}

@test "get_window_class lowercases the output" {
    stub_command xprop 'WM_CLASS(STRING) = "Alpha", "Alpha"'
    run get_window_class "0x08600004"
    assert_success
    assert_output "alpha alpha "
}

@test "get_window_class handles single-value WM_CLASS" {
    stub_command xprop 'WM_CLASS(STRING) = "beta"'
    run get_window_class "0x05800149"
    assert_success
    assert_output "beta "
}

@test "get_window_class returns empty when xprop has no output" {
    stub_command xprop ""
    run get_window_class "0x00000000"
    assert_success
    assert_output ""
}

@test "get_window_class handles a class containing a profile path" {
    stub_command xprop 'WM_CLASS(STRING) = "gamma (/home/user/.config/gamma/Profile 2)", "Gamma"'
    run get_window_class "0x05000004"
    assert_success
    assert_output "gamma (/home/user/.config/gamma/profile 2) gamma "
}
