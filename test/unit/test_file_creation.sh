#!/bin/bash

source ./../../mdscode

TEST_TEMP_DIR="/tmp/mdstest"
mkdir -p "${TEST_TEMP_DIR}"

function test_naming_convention() {
    load_configs
    local filename="!como Esta_el_otoño?"
    local file_extension="cpp"
    apply_naming_convention filename ${file_extension}
    fwktest_assert_string_equals "${filename}" "Como_Esta_El_Otono.cpp"

    filename="!como     Está_él    _otoñío-hoy?"
    file_extension="java"
    apply_naming_convention filename ${file_extension}
    fwktest_assert_string_equals "${filename}" "Como_Esta_El_Otonio_Hoy.java"

    filename="666 !python   Coding     ?¿{}.py.java"
    file_extension="py"
    apply_naming_convention filename ${file_extension}
    fwktest_assert_string_equals "${filename}" "Python_Coding_666.py"
    fwktest_assert_digit_equals ${PROBLEM_ID} 666

    export CASETYPE=UPPERCASE
    PROBLEM_ID=777
    load_configs
    filename="!python   Coding     ?¿{}.py"
    apply_naming_convention filename ${file_extension}
    fwktest_assert_string_equals "${filename}" "PYTHON_CODING_777.py"
    unset CASETYPE
    PROBLEM_ID=
}

function test_separate_filepath_and_filename() {
    local filename="/tmp/path/to/file/competitive"
    local filepath=""
    separate_filepath_and_filename filename filepath
    fwktest_assert_string_equals "${filename}" "competitive"
    fwktest_assert_string_equals "${filepath}" "/tmp/path/to/file"

    filename="germany"
    filepath=""
    separate_filepath_and_filename filename filepath
    fwktest_assert_string_equals "${filename}" "germany"
    fwktest_assert_string_equals "${filepath}" "."

    filename="./local/file/some_file.cpp"
    filepath=""
    separate_filepath_and_filename filename filepath
    fwktest_assert_string_equals "${filename}" "some_file.cpp"
    fwktest_assert_string_equals "${filepath}" "./local/file"

    filename="./some_file.cpp"
    filepath=""
    separate_filepath_and_filename filename filepath
    fwktest_assert_string_equals "${filename}" "some_file.cpp"
    fwktest_assert_string_equals "${filepath}" "."
}

function test_create_file() {
    load_configs
    FILENAME="${TEST_TEMP_DIR}/coding life"
    separate_filepath_and_filename FILENAME FILEPATH
    create_file &> /dev/null < <( echo "n" )
    fwktest_assert_string_equals "${FILENAME}" "Coding_Life.cpp"
    fwktest_assert_file "${TEST_TEMP_DIR}/${FILENAME}"
    fwktest_assert_dir "${BUILD_DIR}/${FILENAME}"
    fwktest_assert_file_content_same_as "${TEST_TEMP_DIR}/${FILENAME}" "${TEMPLATES_DIR}/default.cpp"
    delete_build_data
    fwktest_assert_not_dir "${BUILD_DIR}/${FILENAME}"
    rm -f "${TEST_TEMP_DIR}/${FILENAME}"

    FILENAME="${TEST_TEMP_DIR}/coding life"
    FILETYPE="java"
    separate_filepath_and_filename FILENAME FILEPATH
    create_file &> /dev/null < <( echo "n" )
    fwktest_assert_string_equals "${FILENAME}" "Coding_Life.java"
    fwktest_assert_file "${TEST_TEMP_DIR}/${FILENAME}"
    fwktest_assert_dir "${BUILD_DIR}/${FILENAME}"
    fwktest_assert_file_content_same_as "${TEST_TEMP_DIR}/${FILENAME}" "${TEMPLATES_DIR}/default.java"
    delete_build_data
    fwktest_assert_not_dir "${BUILD_DIR}/${FILENAME}"
    rm -f "${TEST_TEMP_DIR}/${FILENAME}"
}
