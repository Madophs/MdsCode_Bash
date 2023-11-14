#!/bin/bash

PS4='+($(basename ${BASH_SOURCE}):${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
SRC_DIR=${SCRIPT_DIR}/src
RES_DIR=${SCRIPT_DIR}/res
CONFIG_DIR=${SCRIPT_DIR}/configs
CXXINCLUDE_DIR=${RES_DIR}/include/
TEMPLATES_DIR=${RES_DIR}/templates
TEMP_FILE="" # Temporal file
TEMP_DIR="/tmp/mdscode"
TEMP_FLAGS_FILE=${TEMP_DIR}/flags
BUILD_DIR=${SCRIPT_DIR}/build
BUILD_INFO=${BUILD_DIR}/last.txt
IO_DIR=${RES_DIR}/io
TEST_DIR=${RES_DIR}/tests
WIDTH_1ST_OP=5
WIDTH_2ND_OP=28

function create_common_files() {
    mkdir -p ${TEMP_DIR}
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

function open_with_editor() {
    if [[ ${CONFIGS_MAP['OPEN_WITH_EDITOR']} == YES ]]
    then
        local path_to_file=${1}
        local editor_cmd="${CONFIGS_MAP['EDITOR_COMMAND']}"
        editor_cmd=$(echo "${editor_cmd}" | sed "s|{{FILE}}|${path_to_file}|g")
        eval ${editor_cmd}
    fi
}

function get_file_extension() {
    local extension=$(echo ${@} | grep -o -e '\..*' | sed s/^\.//g)
    echo ${extension}
}

function separate_filepath_and_filename() {
    missing_argument_validation 2 ${1} ${2}
    local -n file=${1}
    local -n filepath=${2}
    filepath=$(echo ${file} | grep -o -e '.*\/')
    if [[ -n ${filepath} ]]
    then
        file=$(echo ${file} | sed "s|${filepath}||g")
    fi
}

function get_last_source_file() {
    source ${BUILD_INFO}
    local file=$(echo ${SOURCE_FILE} | awk -F '/' '{print $NF}')
    echo ${file}
}

function is_cmd_option() {
    if [[ -n $(echo ${1} | grep -e '^-') ]]
    then
        echo "YES"
    else
        echo "NO"
    fi
}

function param_validation() {
    if [[ -z ${2} ]]
    then
        cout error "Missing value for param \"${1}\""
    elif [[ $(is_cmd_option ${2}) == "YES" ]]
    then
        cout error "Invalid argument \"${2}\" for param ${1}"
    fi
}

function missing_argument_validation() {
    function_name=${FUNCNAME[1]}
    args_required=${1}
    if [[ -z ${args_required} ]]
    then
        cout error "Missing arguments for ${function_name}"
    fi

    shift
    args_count=$#
    if [[ ${args_required} != ${args_count} ]]
    then
        cout error "Missing arguments for ${function_name} expected ${args_required} provided ${args_count}"
    fi

    args_list=($(echo $@ | paste -d ' '))
    for (( i=0; i < ${#args_list[@]}; i+=1 ))
    do
        if [[ $(is_cmd_option ${args_list[${i}]}) == YES ]]
        then
            cout error "Invalid argument \"${args_list[${i}]}\" for ${function_name}"
        fi
    done
}

function exit_is_zero() {
    local cmd_output=$1
    if [[ ${cmd_output} == 0 ]]
    then
        echo "YES"
    else
        echo "NO"
    fi
}

function is_digit() {
    local arg=${1}
	grep -o -e '^[0-9]*$' <(echo ${arg}) &> /dev/null
    if [[ $(exit_is_zero $?) == NO ]]
    then
        cout error "Invalid value ${arg}"
    fi
}

function set_var() {
    local varname=$1
    local default_value=$2

    env | grep ${varname} &> /dev/null
    if [[ $(exit_is_zero $?) == NO ]]
    then
        export ${varname}=${default_value}
    fi
}

function cout() {
    COLOR=$1
    shift
    MESSAGE="$@"
    case $COLOR in
        red|error|danger)
        echo -e "\e[1;31m[ERROR]\e[0m ${MESSAGE}" >&2
        exit 1
        ;;
        green|success)
        echo -e "\e[1;32m[SUCCESS]\e[0m ${MESSAGE}"
        ;;
        yellow|warning)
        echo -e "\e[1;33m[WARNING]\e[0m ${MESSAGE}" >&2
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
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -c "--create" "Create file"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -b "--build" "Build the given source file (c,cpp,py,java)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--force-build" "Always try to build the given source file (c,cpp,py,java)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -e "--exec" "Executes last compiled file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--exer" "Executes last compiled file without redirecting errors to output file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -i "--io" "Choose the prevefered IO type (I,O,IO). Default: IO"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -t "--test" "Test last compiled bin"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -a "--add [no tests] [src file]" "Add a test case for the specified src file (if not specified, last src file compiled will be taken)."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--set-test [nth test]" "Sets the input of the Nth test as input of \$MDS_INPUT."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -g "--gui" "Run interactive mode with terminal GUI."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -s "--submit " "Submit last built file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--flags" "Edit current compile flags."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -x "--debug" "Self explained"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -h "--help" "Show this"
    printf "\nDeveloped by Jehú Jair Ruiz Villegas\n"
    printf "Contact: jehuruvj@gmail.com\n"
}

function init_vars() {
    set_var ONLINE_JUDGE UVA # UVA Online Judge
}

function enable_debug_if_specified() {
    local all_args=$@
    echo ${all_args} | grep -e '-x' > /dev/null 2>&1
    if [[ $(exit_is_zero $?) == YES ]]
    then
        set -x
    fi
}

function common_setup() {
    create_common_files
    presetup_flags
    init_vars
}
