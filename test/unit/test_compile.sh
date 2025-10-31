#!/bin/bash

source ./../../mdscode

export OPEN_WITH_EDITOR=NO
PRINT_MSG_LEVEL=3

TEST_TEMP_DIR="/tmp/mdstest"
mkdir -p "${TEST_TEMP_DIR}"

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

function helper_file_compile() {
    local file="${1}"
    CREATION=N
    FILETYPE=
    FILENAME=

    start -n "${file}" -c < <(echo "y")
    fwktest_assert_exit_code_equals $? 0
    fwktest_assert_file "${file}"
    load_build_data
    fwktest_assert_string_equals "${file}" "${FULLPATH}"

    CREATION=N
    start -n "${file}" -b
    fwktest_assert_executable "${BINARY_PATH}"
    delete_build_data
    rm -f "${file}"
}
