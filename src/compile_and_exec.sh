#!/bin/bash

ALLOWED_BUILD_FILETYPES=("cpp" "py" "c" "java")

function is_build_required() {
    if [[ ${ALWAYS_BUILD} != Y ]]
    then
        local file_last_time_written=$(ls -l --time-style full-iso "${FULLPATH}" 2> /dev/null | grep -e '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*' -o)
        local bin_last_time_written=$(ls -l --time-style full-iso "${BINARY_PATH}" 2> /dev/null | grep -e '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*' -o)
        if [[ ${file_last_time_written} < ${bin_last_time_written} ]]
        then
            echo "NO"
        fi
    fi
    echo "YES"
}

function show_status_compilation_message() {
    local exit_status=$1
    if [[ $(exit_is_zero ${exit_status}) == NO ]]
    then
        cout error "Errors found during compilation..."
    else
        cout success "Compilation finished successfully."
    fi
}

function compile() {
    cout info "Compiling ${FILENAME}"
    case ${FILETYPE} in
        cpp)
            ${CONFIGS_MAP['CXXCOMPILER']} ${CONFIGS_MAP['CXX_STANDARD']} \
                ${CONFIGS_MAP['CXX_FLAGS']} -I${CXXINCLUDE_DIR} "${FULLPATH}" -o "${BINARY_PATH}"
            show_status_compilation_message $?
            ;;
        c)
            ${CONFIGS_MAP['CCCOMPILER']} ${CC_FLAGS} "${FULLPATH}" -o "${BINARY_PATH}"
            show_status_compilation_message $?
            ;;
        py)
            # python is an intepreted language, therefore we only copy the file to build directory
            cp -f "${FULLPATH}" "${BINARY_PATH}"
            ;;
        java)
            ${CONFIGS_MAP['JAVA_COMPILER']} "${FULLPATH}" -d "${BUILD_DIR}/${FILENAME}"
            show_status_compilation_message $?
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

function build() {
    FILETYPE=$(get_file_extension "${FILENAME}")
    if [[ $(is_allowed_build_filetype ${FILETYPE}) == YES ]]
    then
        if [[ $(is_build_required) = YES ]]
        then
            compile
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
    if [[ ! -f "${BINARY_PATH}" ]]
    then
        cout error "File hasn't been compiled."
    fi

    io_presetup ${1}

    case ${LANG} in
        cpp)
            eval time ${BINARY_PATH} ${IO_ARGS}
            ;;
        c)
            eval time ${BINARY_PATH} ${IO_ARGS}
            ;;
        py)
            eval time ${CONFIGS_MAP['PYTHON_BIN']} ${BINARY_PATH} ${IO_ARGS}
            ;;
        java)
            cd "${BUILD_DIR}/${FILENAME}"
            eval time ${CONFIGS_MAP['JAVA_EXEC']} Main ${IO_ARGS}
            ;;
        *)
            cout error "Unsupported language <${LANG}>."
            ;;
    esac
}
