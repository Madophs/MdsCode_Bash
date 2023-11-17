#!/bin/bash

PS4='+($(basename ${BASH_SOURCE}):${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
SRC_DIR=${SCRIPT_DIR}/src
RES_DIR=${SCRIPT_DIR}/res
CONFIG_DIR=${SCRIPT_DIR}/configs
CXXINCLUDE_DIR=${RES_DIR}/include/
TEMPLATES_DIR=${RES_DIR}/templates
TEMP_FILE="" # Temporal file
TEMP_DIR="/tmp/mdscode"
BUILD_DIR=${SCRIPT_DIR}/build
BUILD_INFO=${BUILD_DIR}/last.txt
FLAGS_DIR=${BUILD_DIR}/flags
IO_DIR=${RES_DIR}/io
MDS_INPUT=${IO_DIR}/input
MDS_OUTPUT=${IO_DIR}/output
TEST_DIR=${RES_DIR}/tests
WIDTH_1ST_OP=5
WIDTH_2ND_OP=28

function create_common_files() {
    mkdir -p ${TEMP_DIR}
    mkdir -p ${BUILD_DIR}
    mkdir -p ${IO_DIR}
    mkdir -p ${TEST_DIR}
    mkdir -p ${FLAGS_DIR}
    touch ${MDS_INPUT} ${MDS_OUTPUT}
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

function cout() {
    local color=$1
    shift
    local messsage="$@"
    case ${color} in
        red|error|danger)
        echo -e "\e[1;31m[ERROR]\e[0m ${messsage}" >&2
        exit 1
        ;;
        green|success)
        echo -e "\e[1;32m[SUCCESS]\e[0m ${messsage}" >&2
        ;;
        yellow|warning)
        echo -e "\e[1;33m[WARNING]\e[0m ${messsage}" >&2
        ;;
        blue|info)
        echo -e "\e[1;36m[INFO]\e[0m ${messsage}" >&2
        ;;
    esac
}

function get_test_folder_name() {
    missing_argument_validation 1 ${1}
    echo $(echo ${1} | sed 's/\./_/g')
}

function get_filetype_by_language() {
    missing_argument_validation 1 $1
    local language=${1}
    case ${language} in
        C++)
            echo "cpp"
            ;;
        "C Language")
            echo "c"
            ;;
        Java)
            echo "java"
            ;;
        Python)
            echo "py"
            ;;
        Rust)
            echo "rs"
            ;;
        *)
            cout error "Invalid language"
            ;;
    esac
}

function save_flags() {
    case ${FILETYPE} in
        cpp)
            echo "export CXX_STANDARD=\"${CONFIGS_MAP['CXX_STANDARD']}\"" > ${FLAGS_DIR}/${FILENAME}.sh
            echo "export CXXCOMPILER=\"${CONFIGS_MAP['CXXCOMPILER']}\"" >> ${FLAGS_DIR}/${FILENAME}.sh
            echo "export CXX_FLAGS=\"${CONFIGS_MAP['CXX_FLAGS']}\"" >> ${FLAGS_DIR}/${FILENAME}.sh
            ;;
        c)
            echo "export CCCOMPILER=\"${CONFIGS_MAP['CCCOMPILER']}\"" > ${FLAGS_DIR}/${FILENAME}.sh
            echo "export CC_FLAGS=\"${CONFIGS_MAP['CC_FLAGS']}\"" >> ${FLAGS_DIR}/${FILENAME}.sh
            ;;
    esac
}

function save_build_info() {
    echo LANG=\"${FILETYPE}\" > ${BUILD_INFO}
    cp -p ${FILEPATH}${FILENAME} ${TEMP_DIR}/${FILENAME}
    echo TMP_SOURCE_FILE=\"${TEMP_DIR}/${FILENAME}\" >> ${BUILD_INFO}
    echo ORIGINAL_SOURCE="$(realpath ${FILEPATH}${FILENAME})" >> ${BUILD_INFO}
    save_flags
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

function delete_old_files() {
    local target_dir="${1}"
    local files=($(ls -l --time-style=full-iso "${target_dir}" | tail -n +2 | awk '{print $6" "$NF}' | paste -s -d ' '))
    local current_date=$(date +%s)
    for (( i=0, j=1; i < ${#files[@]}; i+=2,j+=2 ))
    do
        local creation_date=$(date +%s -d "${files[${i}]}")
        local days_diff=$(( (${current_date} - ${creation_date}) / (60 * 60 * 24) ))
        if [[ ${days_diff} -ge 14 ]]
        then
            rm -rf ${target_dir}/${files[${j}]} &> /dev/null
        fi
    done
}

function open_flags() {
    local last_built_file=$(get_last_source_file)
    local path_to_file="${FLAGS_DIR}/${last_built_file}.sh"
    if [[ -f ${path_to_file} ]]
    then
        open_with_editor ${path_to_file}
    else
        cout error "Flags file not found."
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
    source ${BUILD_INFO} > /dev/null 2>&1
    local file=$(echo ${ORIGINAL_SOURCE} | awk -F '/' '{print $NF}')
    echo ${file}
}

function is_cmd_option() {
    if [[ -n $(printf "%s" "${1}" | grep -e '^-') ]]
    then
        echo "YES"
    else
        echo "NO"
    fi
}
function set_and_shift_cwsrc_file() {
    if [[ -n ${1} && $(is_cmd_option "${1}") == NO ]]
    then
        echo "shift; CWSRC_FILE=${1}"
    else
        CWSRC_FILE=$(get_last_source_file)
        echo "CWSRC_FILE=${CWSRC_FILE}"
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

function exit_is_zero() {
    local cmd_output=$1
    if [[ ${cmd_output} == 0 ]]
    then
        echo "YES"
    else
        echo "NO"
    fi
}

function exit_is_not_zero() {
    local cmd_output=$1
    if [[ ${cmd_output} == 1 ]]
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

function is_vim_the_father() {
    local vim_cmd=$(which vim)
    local nvim_cmd=$(which nvim)
    local nvim_qt_cmd=$(which nvim-qt)
    local child=$(ps $$ | tail -n 1 | awk '{print $1}')
    local parent=
    while true
    do
        parent=$(ps -o ppid -p ${child} | tail -n 1 | awk '{print $1}')
        if [[ ${parent} == 1 ]]
        then
            echo "NO"
            break
        fi

        ps -o command -p ${parent} | tail -n 1 | grep -o -E "${vim_cmd}|${nvim_cmd}|${nvim_qt_cmd}" &> /dev/null
        if [[ $(exit_is_zero $?) == YES ]]
        then
            echo "YES"
            break
        fi
        child=${parent}
    done
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
    delete_old_files ${TEST_DIR}
    delete_old_files ${FLAGS_DIR}
    init_vars
}

function display_help() {
    printf "Usage: mdscode [options] file...\n"
    printf "Options:\n"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -f "--file [type]" "Specify the file type (c,cpp,py,java). Default: cpp"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -n "--name [args...]" "Filename"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--ignore-rename" "Ignore applying naming convensions."
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
    exit 0
}
