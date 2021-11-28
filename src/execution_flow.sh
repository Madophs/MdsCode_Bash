#!/bin/bash

source $SRC_DIR/file_creation.sh
source $SRC_DIR/testing.sh
source $SRC_DIR/compile_and_exec.sh

# Execution flow
create_file

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
