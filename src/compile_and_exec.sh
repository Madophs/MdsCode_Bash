#!/bin/bash

function build() {
    FILE_TYPE=$(echo $FILENAME | awk -F '.' '{print $NF}')

    if [[ $FILE_TYPE == "cpp" ]]
    then
        $CXXCOMPILER $MDS_CXX_FLAGS $FILENAME -o $BUILD_DIR/run
        if [[ $? != 0 ]]
        then
            echo "[ERROR] Errors found during compilation..."
            exit 1
        fi
    elif [[ $FILE_TYPE == "c" ]]
    then
        $CCCOMPILER $MDS_CC_FLAGS $FILENAME -o $BUILD_DIR/run
        if [[ $? != 0 ]]
        then
            echo "[ERROR] Errors found during compilation..."
            exit 1
        fi
    elif [[ $FILE_TYPE == "py" ]]
    then
        cp -f $FILENAME $BUILD_DIR/run.py
    fi

    echo $FILE_TYPE > $BUILD_DIR/last.txt
}

function io_presetup() {
    IO_ARGS=""
    if [[ $IO_TYPE == "IO" ]]
    then
        IO_ARGS=" < ${IO_DIR}/input > ${IO_DIR}/output"
    elif [[ $IO_TYPE == "I" ]]
    then
        IO_ARGS=" < ${IO_DIR}/input"
    elif [[ $IO_TYPE == "O" ]]
    then
        IO_ARGS=" > ${IO_DIR}/output"
    elif [[ $IO_TYPE != "N" ]]
    then
        echo "[ERROR] Unknown IO type: ${IO_TYPE}."
    fi
}

function execute() {
    if [[ ! -f $BUILD_DIR/last.txt ]]
    then
        echo "[ERROR] No last build found."
    fi

    LAST_BUILD_TYPE=$(cat $BUILD_DIR/last.txt)

    io_presetup
    if [[ $LAST_BUILD_TYPE == "cpp" ]]
    then
        eval $BUILD_DIR/run $IO_ARGS
    elif [[ $LAST_BUILD_TYPE == "c" ]]
    then
        eval $BUILD_DIR/run $IO_ARGS
    elif [[ $LAST_BUILD_TYPE == "py" ]]
    then
        eval python3 $BUILD_DIR/run.py $IO_ARGS
    else
        echo "[ERROR] No last build found."
        exit 1
    fi
}
