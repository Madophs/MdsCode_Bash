#!/bin/bash

function build() {
    ALLOWED_FILE_TYPES=("cpp" "py" "c" "java")
    PREVIOUS_BUILD=$1
    FILE_TYPE=$(echo $FILENAME | awk -F '.' '{print $NF}')

    IS_ALLOWED_FILE_TYPE=$(echo ${ALLOWED_FILE_TYPES} | grep -o ${FILE_TYPE})
    if [[ -n ${IS_ALLOWED_FILE_TYPE} ]]
    then
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
            cp -f $FILENAME $BUILD_DIR/run.py
        fi

        if [[ -z ${PREVIOUS_BUILD} ]]; then
            # Metadata for future builds
            echo $FILE_TYPE > $BUILD_DIR/last.txt
            cp $FILENAME $TEMP_DIR/$FILENAME
            echo ${TEMP_DIR}/${FILENAME} >> $BUILD_DIR/last.txt
        fi
    else
        # If we are trying to build a different file from mention aboved, let's built the file found in last.txt
        if [[ -f ${BUILD_DIR}/last.txt ]]
        then
            cout warning "[WARNING] Filetype not allowed, trying to build last compiled file."
            FILENAME=$(cat ${BUILD_DIR}/last.txt | tail -n 1)
            build previous
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
        eval $BUILD_DIR/run $IO_ARGS
    elif [[ $LAST_BUILD_TYPE == "c" ]]
    then
        eval $BUILD_DIR/run $IO_ARGS
    elif [[ $LAST_BUILD_TYPE == "py" ]]
    then
        eval python3 $BUILD_DIR/run.py $IO_ARGS
    else
        cout error "[ERROR] No last build found."
        exit 1
    fi
}


