#!/bin/bash

source ./../../mdscode
source ./helper_functions.sh

function test_allowed_files() {
    local is_allowed=$(is_allowed_build_filetype "java")
    fwktest_assert_string_equals "${is_allowed}" "YES"
    is_allowed=$(is_allowed_build_filetype "php")
    fwktest_assert_string_equals "${is_allowed}" "NO"
}

function test_cpp_compile() {
    local file_cpp="/tmp/mdstest/FWKSum_Numbers.cpp"
    helper_file_compile "${file_cpp}"
}

function test_c_compile() {
    local file_c="/tmp/mdstest/FWKSum_Numbers.c"
    helper_file_compile "${file_c}"
}

function test_python_compile() {
    local file_py="/tmp/mdstest/FWKSum_Numbers.py"
    helper_file_compile "${file_py}"
}

function test_java_compile() {
    local file_java="/tmp/mdstest/FWKSum_Numbers.java"
    helper_file_compile "${file_java}"
}
