#!/bin/bash

source $SRC_DIR/file_creation.sh
source $SRC_DIR/compile_and_exec.sh

# Execution flow
create_file

if [[ $BUILDING == "Y" ]]
then
    build
fi

if [[ $EXECUTION == "Y" ]]
then
    execute
fi
