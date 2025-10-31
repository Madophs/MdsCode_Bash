#!/bin/bash

source ../../src/common.sh

function test_get_file_extension() {
    local file_extension=$(get_file_extension "some_file_333.cpp")
    fwktest_assert_string_equals "${file_extension}" "cpp"
}
