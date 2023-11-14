#!/bin/bash

ALLOWED_BUILD_FILETYPES=("cpp" "py" "c" "java")

function is_build_required() {
    if [[ ${ALWAYS_BUILD} != Y && -f ${BUILD_INFO} ]]
    then
        source ${BUILD_INFO} # Last TMP_SOURCE_FILE built
        TMP_SOURCE_FILE=$(echo ${TMP_SOURCE_FILE} | awk -F '/' '{print $NF}')
        local current_file=$(echo "${FILEPATH}${FILENAME}" | awk -F '/' '{print $NF}')
        if [[ "${current_file}" == "${TMP_SOURCE_FILE}" ]]
        then
            local executable=${BUILD_DIR}/run
            local file_last_time_written=$(ls -l --time-style full-iso "${FILEPATH}${FILENAME}" | grep -e '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*' -o)
            local bin_last_time_written=$(ls -l --time-style full-iso ${executable} | grep -e '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*' -o)
            if [[ ${file_last_time_written} < ${bin_last_time_written} ]]
            then
                echo "NO"
            fi
        fi
    fi
    echo "YES"
}

function show_status_compilation_message()
{
    local exit_status=$1
    if [[ $(exit_is_zero ${exit_status}) == NO ]]
    then
        cout error "Errors found during compilation..."
    else
        cout success "Compilation finished successfully."
    fi
}

function build_file() {
    cout info "Compiling ${FILENAME}"
    case ${FILETYPE} in
        cpp)
            ${CONFIGS_MAP['CXXCOMPILER']} ${CONFIGS_MAP['CXX_STANDARD']} \
                ${CONFIGS_MAP['CXX_FLAGS']} -I${CXXINCLUDE_DIR} ${FILEPATH}${FILENAME} -o ${BUILD_DIR}/run
            show_status_compilation_message $?
            ;;
        c)
            ${CONFIGS_MAP['CCCOMPILER']} ${CC_FLAGS} ${FILEPATH}${FILENAME} -o ${BUILD_DIR}/run
            show_status_compilation_message $?
            ;;
        py)
            # python is an intepreted language, therefore we only copy the file to build directory
            cp -f ${FILEPATH}${FILENAME} ${BUILD_DIR}/run
            ;;
    esac
}

function is_allowed_build_filetype() {
    echo ${ALLOWED_BUILD_FILETYPES[*]} | grep -o -w -e "${1}" > /dev/null 2>&1
    if [[ $(exit_is_zero $?) == YES ]]
    then
        echo "YES"
    else
        echo "NO"
    fi
}

function save_last_build_info() {
    CWSRC_FILE=${FILENAME}

    # Last source file built
    echo LANG=\"${FILETYPE}\" > ${BUILD_INFO}
    cp -p ${FILEPATH}${FILENAME} ${TEMP_DIR}/${FILENAME}
    echo TMP_SOURCE_FILE=\"${TEMP_DIR}/${FILENAME}\" >> ${BUILD_INFO}
    echo ORIGINAL_SOURCE="$(realpath ${FILEPATH}${FILENAME})" >> ${BUILD_INFO}

    save_flags
}

function update_flags() {
    local last_file_built=$(get_last_source_file)
    if [[ ${last_file_built} != ${FILENAME} ]]
    then
        read_custom_configs ${FILENAME}
    fi
}

function build() {
    update_flags
    FILETYPE=$(get_file_extension "${FILENAME}")
    if [[ $(is_allowed_build_filetype ${FILETYPE}) == YES ]]
    then
        if [[ $(is_build_required) = YES ]]
        then
            build_file
            save_last_build_info
        else
            cout warning "Skipping build, using previous executable."
        fi
    else
        cout error "Failed to build. Filetype not allowed."
    fi
}

function io_presetup() {
    if [[ -n ${1} ]]
    then
        local input_file="${1}"
        IO_ARGS=" < ${input_file} > ${MDS_OUTPUT}"
        return 0
    fi

    case ${IO_TYPE} in
        IO)
            IO_ARGS=" < ${MDS_INPUT} > ${MDS_OUTPUT} ${REDIRECT_OP}"
            ;;
        I)
            IO_ARGS=" < ${MDS_INPUT}"
            ;;
        O)
            IO_ARGS=" > ${MDS_OUTPUT} ${REDIRECT_OP}"
            ;;
        N)
            IO_ARGS=""
            ;;
        *)
            cout error "Unknown IO type: ${IO_TYPE}."
            ;;
    esac
}

function execute() {
    if [[ ! -f ${BUILD_INFO} ]]
    then
        cout error "File hasn't been compiled."
    fi

    io_presetup ${1}
    source ${BUILD_INFO}

    case ${LANG} in
        cpp)
            eval time ${BUILD_DIR}/run ${IO_ARGS}
            ;;
        c)
            eval time ${BUILD_DIR}/run ${IO_ARGS}
            ;;
        py)
            eval time ${CONFIGS_MAP['PYTHON_BIN']} ${BUILD_DIR}/run ${IO_ARGS}
            ;;
        *)
            cout error "No last build info found."
            ;;
    esac
}
