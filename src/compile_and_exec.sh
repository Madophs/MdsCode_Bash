#!/bin/bash

BUILD_REQUIRED="Y"

function build_required() {
    if [[ -f ${BUILD_INFO} ]]
    then
        source ${BUILD_INFO} # Last SOURCE_FILE built
        SOURCE_FILE=$(echo ${SOURCE_FILE} | awk -F '/' '{print $NF}')
        CURRENT_FILE=$(echo ${FILENAME} | awk -F '/' '{print $NF}')
        if [[ "${CURRENT_FILE}" == "${SOURCE_FILE}" ]]
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
    if [[ $BUILD_FILETYPE == "cpp" ]]
    then
        $CXXCOMPILER $MDS_CXX_FLAGS -I$CXXINCLUDE_DIR $FILENAME -o $BUILD_DIR/run
        if [[ $? != 0 ]]
        then
            cout error "[ERROR] Errors found during compilation..."
            exit 1
        fi
    elif [[ $BUILD_FILETYPE == "c" ]]
    then
        $CCCOMPILER $MDS_CC_FLAGS $FILENAME -o $BUILD_DIR/run
        if [[ $? != 0 ]]
        then
            cout error "[ERROR] Errors found during compilation..."
            exit 1
        fi
    elif [[ $BUILD_FILETYPE == "py" ]]
    then
        cp -f $FILENAME $BUILD_DIR/run
    fi
}

function build() {
    BUILD_FILETYPE=$(echo $FILENAME | awk -F '.' '{print $NF}')

    IS_ALLOWED_BUILD_FILETYPE=$(echo ${ALLOWED_BUILD_FILETYPES} | grep -o ${BUILD_FILETYPE})
    if [[ -n ${IS_ALLOWED_BUILD_FILETYPE} ]]
    then
        build_required

        if [[ ${BUILD_REQUIRED} = "Y" ]]
        then
            cout green "Building ${FILENAME}"
            build_file

            echo LANG=\"${BUILD_FILETYPE}\" > ${BUILD_INFO}
            cp -p ${FILENAME} ${TEMP_DIR}/${FILENAME}
            echo SOURCE_FILE=\"${TEMP_DIR}/${FILENAME}\" >> ${BUILD_INFO}
        fi
    else
        # If we are trying to build a different file from mention aboved, let's built the file found in last.txt
        if [[ -f ${BUILD_INFO} ]]
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
            IO_ARGS=" < ${IO_DIR}/input &> ${IO_DIR}/output"
        elif [[ $IO_TYPE == "I" ]]
        then
            IO_ARGS=" < ${IO_DIR}/input"
        elif [[ $IO_TYPE == "O" ]]
        then
            IO_ARGS=" &> ${IO_DIR}/output"
        elif [[ $IO_TYPE != "N" ]]
        then
            cout error "[ERROR] Unknown IO type: ${IO_TYPE}."
        fi
    fi
}

function execute() {
    if [[ ! -f ${BUILD_INFO} ]]
    then
        cout error "[ERROR] No last build found."
        exit 1
    fi

    source ${BUILD_INFO}

    io_presetup ${1}

    if [[ $LANG == "cpp" ]]
    then
        eval time $BUILD_DIR/run $IO_ARGS
    elif [[ $LANG == "c" ]]
    then
        eval time $BUILD_DIR/run $IO_ARGS
    elif [[ $LANG == "py" ]]
    then
        eval time python3 $BUILD_DIR/run.py $IO_ARGS
    else
        cout error "[ERROR] No last build found."
        exit 1
    fi
}


