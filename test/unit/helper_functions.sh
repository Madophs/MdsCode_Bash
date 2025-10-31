#!/bin/bash

export OPEN_WITH_EDITOR=NO
PRINT_MSG_LEVEL=3

TEST_TEMP_DIR="/tmp/mdstest"
mkdir -p "${TEST_TEMP_DIR}"

function helper_reset_used_variables() {
    PROBLEM_URL=
    ONLINE_JUDGE=
    FILENAME=
    FILETYPE=
    FILEPATH=
    CREATE=N
    PROBLEM_ID=
}

function helper_file_creation_by_url() {
    local problem_url="${1}"
    local expected_filename="${2}"

    helper_reset_used_variables
    pushd "${TEST_TEMP_DIR}" &> /dev/null

    start -u "${problem_url}" -c -f cpp < <(echo "y")
    fwktest_assert_string_equals "${expected_filename}" "${FILENAME}"
    fwktest_assert_file "${TEST_TEMP_DIR}/${expected_filename}"
    fwktest_assert_file "${TEST_DIR}/${expected_filename}/test_input_0.txt"
    fwktest_assert_file "${TEST_DIR}/${expected_filename}/test_output_0.txt"
    fwktest_assert_file_content_same_as "${TEST_DIR}/${expected_filename}/test_input_0.txt" "${UNIT_TEST_DIR}/online_judge/assets/${expected_filename}.input"
    fwktest_assert_file_content_same_as "${TEST_DIR}/${expected_filename}/test_output_0.txt" "${UNIT_TEST_DIR}/online_judge/assets/${expected_filename}.output"
    delete_build_data
    rm -f "${TEST_TEMP_DIR}/${expected_filename}"

    popd &> /dev/null
    helper_reset_used_variables
}

function helper_file_compile() {
    local file="${1}"
    helper_reset_used_variables
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
