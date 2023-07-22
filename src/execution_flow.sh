#!/bin/bash

source $SRC_DIR/file_creation.sh
source $SRC_DIR/testing.sh
source $SRC_DIR/compile_and_exec.sh
source $SRC_DIR/interactive_mode.sh
source $SRC_DIR/submit.sh

if [[ $GUI == "Y" ]]
then
    start_gui
else
    # Execution flow
    if [[ $CREATION == "Y" ]]
    then
        create_file
    fi

    if [[ $BUILDING == "Y" ]]
    then
        build
    fi

    if [[ $CREATE_TESTS == "Y" ]]
    then
        set_test
    fi

    if [[ $SET_TEST != "-1" ]]
    then
        set_nth_test_as_input
    fi

    if [[ $EXECUTION == "Y" ]]
    then
        if [[ $TESTING == "Y" ]]
        then
            testing
        else
            execute
        fi
    fi

    if [[ $OPEN_FLAGS == "Y" ]]
    then
        open_with_vim ${TEMP_FLAGS_FILE}
    fi

    if [[ $SUBMIT == "Y" ]]
    then
        submit_code
    fi
fi

