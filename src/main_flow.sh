#!/bin/bash

source ${SRC_DIR}/common.sh
source ${SRC_DIR}/configs.sh
source ${SRC_DIR}/parser.sh
source ${SRC_DIR}/file_creation.sh
source ${SRC_DIR}/testing.sh
source ${SRC_DIR}/compile_and_exec.sh
source ${SRC_DIR}/guimode.sh
source ${SRC_DIR}/submit.sh

function start_flow() {
    if [[ ${GUI} == Y ]]
    then
        start_gui
    fi

    if [[ ${CREATION} == Y ]]
    then
        create_file
    fi

    if [[ ${CREATE_TESTS} == Y ]]
    then
        set_test
    fi

    if [[ ${BUILDING} == Y ]]
    then
        build
    fi

    if [[ ${SET_TEST} != -1 ]]
    then
        set_nth_test_as_input
    fi

    if [[ ${EXECUTION} == Y ]]
    then
        if [[ ${TESTING} == Y ]]
        then
            testing
        else
            execute
        fi
    fi

    if [[ ${OPEN_FLAGS} == Y ]]
    then
        open_flags
    fi

    if [[ ${SUBMIT} == Y ]]
    then
        submit_code
    fi
}

function start() {
    enable_debug_if_specified "$@"
    parse_args "$@"
    common_setup
    load_configs
    start_flow
}

