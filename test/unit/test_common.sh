#!/bin/bash

source ../../mdscode
source ./helper_functions.sh

function test_get_file_extension() {
    local file_extension=$(get_file_extension "some_file_333.cpp")
    fwktest_assert_string_equals "${file_extension}" "cpp"
}

function test_delete_old_files() {
    local -i current_epoch_date=$(date +%s)
    local -i past_epoch_date_61_days=$(( current_epoch_date - (60 * 60 * 24 * 61) ))
    local past_datetime_61_days="$(date -d "@${past_epoch_date_61_days}")"
    mkdir -p "${TEST_TEMP_DIR}/files"
    touch -m -d "${past_datetime_61_days}" "${TEST_TEMP_DIR}/files/inside.txt"
    touch -m -d "${past_datetime_61_days}" "${TEST_TEMP_DIR}/files/inside2.txt"
    touch -m -d "${past_datetime_61_days}" "${TEST_TEMP_DIR}/todelete1.txt"
    touch -m -d "${past_datetime_61_days}" "${TEST_TEMP_DIR}/todelete2.txt"
    touch -m -d "${past_datetime_61_days}" "${TEST_TEMP_DIR}/files"

    touch "${TEST_TEMP_DIR}/nottodelete.txt"

    export DAYS_BEFORE_DELETION=60
    load_configs
    delete_old_files "${TEST_TEMP_DIR}"

    fwktest_assert_not_dir "${TEST_TEMP_DIR}/files"
    fwktest_assert_not_file "${TEST_TEMP_DIR}/todelete1.txt"
    fwktest_assert_not_file "${TEST_TEMP_DIR}/todelete2.txt"
    fwktest_assert_file "${TEST_TEMP_DIR}/nottodelete.txt"
    rm -f "${TEST_TEMP_DIR}/nottodelete.txt"
}
