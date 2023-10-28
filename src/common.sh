#!/bin/bash

SRC_DIR=${SCRIPT_DIR}/src
RES_DIR=${SCRIPT_DIR}/res
CXXINCLUDE_DIR=${RES_DIR}/include/
TEMPLATES_DIR=${RES_DIR}/templates
FILENAME=""
TEMP_FILE="" # Temporal file
TEMP_DIR="/tmp/mdscode"
TEMP_FLAGS_FILE=${TEMP_DIR}/flags
BUILD_DIR=${SCRIPT_DIR}/build
BUILD_INFO=${BUILD_DIR}/last.txt
IO_DIR=${RES_DIR}/io
TEST_DIR=${RES_DIR}/tests
NO_TEST=0
SET_TEST="-1"
CREATE_TESTS="N"
TESTING="N"
IO_ARGS=""
WIDTH_1ST_OP=5
WIDTH_2ND_OP=28
GUI="N"
SERVERNAME="Competitive"
OPEN_FLAGS="N"
SUBMIT="N"
ALLOWED_BUILD_FILETYPES=("cpp" "py" "c" "java")

# Global variables for naming conventions
# CASETYPE
# UCWORDS uppercase the first letter of every word
# UPPERCASE Y LOWERCASE
CASETYPE="UCWORDS"
WHITESPACE_REPLACE="_"

# C/C++ variables
CXXCOMPILER="g++"
MDS_CXX_FLAGS="-std=c++17 -O0 -Wall -Wextra -g -D__MDS_DEBUG__"
CCCOMPILER="gcc"
MDS_CC_FLAGS="-Wall -Wextra -g"

function common_setup() {
    mkdir -p "/tmp/mdscode"
    mkdir -p ${BUILD_DIR}
    mkdir -p ${IO_DIR}
    mkdir -p ${TEST_DIR}
    touch ${IO_DIR}/input ${IO_DIR}/output
}

function presetup_flags() {
    if [[ -f ${TEMP_FLAGS_FILE} ]]; then
        MDS_CXX_FLAGS=$(cat ${TEMP_FLAGS_FILE})
    else
        echo ${MDS_CXX_FLAGS} > ${TEMP_FLAGS_FILE}
    fi
}

function open_with_vim() {
    RUNNING=$(ps -ef | grep "vim" | grep "\-\-servername ${SERVERNAME}")
    FILE=$1
    if [[ -n ${RUNNING} ]]
    then
        vim --servername ${SERVERNAME} --remote ${FILE}
    else
        vim --servername ${SERVERNAME} ${FILE}
    fi
}

function get_last_source_file() {
    source ${BUILD_INFO}
    RET=$(echo ${SOURCE_FILE} | awk -F '/' '{print $NF}')
    echo ${RET}
}

function is_cmd_option() {
    ARG=${1}
    if [[ -n $(echo ${ARG} | grep -e '^-') ]]
    then
        echo "YES"
    else
        echo "NO"
    fi
}

function missing_argument_validation() {
    ARG=${1}
    if [[ -z ${2} ]]
    then
        cout error "Missing argument for \"${ARG}\""
    elif [[ $(is_cmd_option ${2}) == "YES" ]]
    then
        cout error "Invalid argument \"${2}\""
    fi
}

function any_error() {
    CMD_OUTPUT=$1
    if [[ ${CMD_OUTPUT} == 0 ]]
    then
        echo "NO"
    else
        echo "YES"
    fi
}

function is_digit() {
    ARG=${1}
	grep -o -e '^[0-9]*$' <(echo ${ARG}) &> /dev/null
    if [[ $(any_error $?) == "YES" ]]
    then
        cout error "Invalid value ${ARG}"
    fi
}

function set_var() {
    VARNAME=$1
    DEFAULT_VALUE=$2

    env | grep ${VARNAME} &> /dev/null
    if [[ $(any_error $?) == "YES" ]]
    then
        export ${VARNAME}=${DEFAULT_VALUE}
    fi
}

function cout() {
    COLOR=$1
    MESSAGE=$2
    case $COLOR in
        red|error|danger)
        echo -e "\e[1;31m[ERROR]\e[0m ${MESSAGE}"
        exit 1
        ;;
        green|success)
        echo -e "\e[1;32m[SUCCESS]\e[0m ${MESSAGE}"
        ;;
        yellow|warning)
        echo -e "\e[1;33m[WARNING]\e[0m ${MESSAGE}"
        ;;
        blue|info)
        echo -e "\e[1;34m[INFO]\e[0m ${MESSAGE}"
        ;;
    esac
}

function display_help() {
    printf "Usage: mdscode [options] file...\n"
    printf "Options:\n"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -f "--file [type]" "Specify the file type (c,cpp,py,java). Default: cpp"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -n "--name [args...]" "Filename"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -b "--build [file]" "Build the given source file (c,cpp,py,java)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -e "--exec" "Executes last compiled file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--exer" "Executes last compiled file without redirecting errors to output file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -i "--io" "Choose the prevefered IO type (I,O,IO). Default: IO"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -t "--test" "Test last compiled bin"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -a "--add [no tests] [src file]" "Add a test case for the specified src file (if not specified, last src file compiled will be taken)."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--set-test [nth test]" "Sets the input of the Nth test as input of \$MDS_INPUT."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -g "--gui" "Run interactive mode with terminal GUI."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -s "--submit " "Submit last built file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--flags" "Edit current compile flags."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -h "--help" "Show this"
    printf "\nDeveloped by Jehú Jair Ruiz Villegas\n"
    printf "Contact: jehuruvj@gmail.com\n"
}

function init_vars() {
    set_var ONLINE_JUDGE UVA # UVA Online Judge
}

function init() {
    presetup_flags
    common_setup
    init_vars
}
