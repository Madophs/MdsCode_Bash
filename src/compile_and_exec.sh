#!/bin/bash

BUILD_REQUIRED="Y"

function build_required() {
    if [[ -f ${BUILD_DIR}/last.txt ]]
    then
        LAST_FILE_BUILT=$(cat $BUILD_DIR/last.txt | tail -n 1 | awk -F '/' '{print $NF}')
        CURRENT_FILE=$(echo ${FILENAME} | tail -n 1 | awk -F '/' '{print $NF}')
        if [[ "${CURRENT_FILE}" == "${LAST_FILE_BUILT}" ]]
        then
            BINARY=${BUILD_DIR}/run
            FILE_LAST_TIME_WRITTEN=$(ls -l --time-style full-iso ${FILENAME} | grep -e '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*' -o)
            BIN_LAST_TIME_WRITTEN=$(ls -l --time-style full-iso ${BINARY} | grep -e '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*' -o)
            if [[ ${FILE_LAST_TIME_WRITTEN} < ${BIN_LAST_TIME_WRITTEN} ]]
            then
                BUILD_REQUIRED="N"
                cout warning "[INFO] Skipping build, using previous executable."
            fi
        fi
    fi
}

function build_file() {
    if [[ $FILE_TYPE == "cpp" ]]
    then
        $CXXCOMPILER $MDS_CXX_FLAGS $FILENAME -o $BUILD_DIR/run
        if [[ $? != 0 ]]
        then
            cout error "[ERROR] Errors found during compilation..."
            exit 1
        fi
    elif [[ $FILE_TYPE == "c" ]]
    then
        $CCCOMPILER $MDS_CC_FLAGS $FILENAME -o $BUILD_DIR/run
        if [[ $? != 0 ]]
        then
            cout error "[ERROR] Errors found during compilation..."
            exit 1
        fi
    elif [[ $FILE_TYPE == "py" ]]
    then
        cp -f $FILENAME $BUILD_DIR/run
    fi
}

function build() {
    ALLOWED_FILE_TYPES=("cpp" "py" "c" "java")
    FILE_TYPE=$(echo $FILENAME | awk -F '.' '{print $NF}')

    IS_ALLOWED_FILE_TYPE=$(echo ${ALLOWED_FILE_TYPES} | grep -o ${FILE_TYPE})
    if [[ -n ${IS_ALLOWED_FILE_TYPE} ]]
    then

        build_required

        if [[ ${BUILD_REQUIRED} = "Y" ]]
        then
            cout green "Building ${FILENAME}"
            build_file

            echo $FILE_TYPE > $BUILD_DIR/last.txt
            cp -p $FILENAME $TEMP_DIR/$FILENAME
            echo ${TEMP_DIR}/${FILENAME} >> $BUILD_DIR/last.txt
        fi
    else
        # If we are trying to build a different file from mention aboved, let's built the file found in last.txt
        if [[ -f ${BUILD_DIR}/last.txt ]]
        then
            cout warning "[WARNING] Filetype not allowed, skipping building stage."
        fi
    fi
}

function io_presetup() {
    if [[ ! -z ${1} ]]
    then
        echo "" > ${IO_DIR}/output
        IO_ARGS=" < ${1} > ${IO_DIR}/output"
    else
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
            cout error "[ERROR] Unknown IO type: ${IO_TYPE}."
        fi
    fi
}

function execute() {
    if [[ ! -f $BUILD_DIR/last.txt ]]
    then
        cout error "[ERROR] No last build found."
        exit 1
    fi

    LAST_BUILD_TYPE=$(cat $BUILD_DIR/last.txt | head -n 1)

    io_presetup ${1}

    if [[ $LAST_BUILD_TYPE == "cpp" ]]
    then
        eval time $BUILD_DIR/run $IO_ARGS
    elif [[ $LAST_BUILD_TYPE == "c" ]]
    then
        eval time $BUILD_DIR/run $IO_ARGS
    elif [[ $LAST_BUILD_TYPE == "py" ]]
    then
        eval time python3 $BUILD_DIR/run.py $IO_ARGS
    else
        cout error "[ERROR] No last build found."
        exit 1
    fi
}


