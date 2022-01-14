#!/bin/bash

source $SRC_DIR/file_creation.sh
source $SRC_DIR/testing.sh
source $SRC_DIR/compile_and_exec.sh
source $SRC_DIR/interactive_mode.sh

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

    if [[ $EXECUTION == "Y" ]]
    then
        if [[ $TESTING == "Y" ]]
        then
            testing
        else
            execute
        fi
    fi
fi

