#!/bin/bash

TIMEFORMAT="%Rs real %Us user %Ss sys"
PS4='+($(basename ${BASH_SOURCE}):${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# App directories
SRC_DIR="${SCRIPT_DIR}/src"
RES_DIR="${SCRIPT_DIR}/res"
CONFIG_DIR="${SCRIPT_DIR}/configs"
CXXINCLUDE_DIR="${RES_DIR}/include/"
TEMPLATES_DIR="${RES_DIR}/templates"

# App data directories
LOCAL_DATA_DIR="${HOME}/.local/share/mdscode"
IO_DIR="${LOCAL_DATA_DIR}/io"
TEST_DIR="${LOCAL_DATA_DIR}/tests"
BUILD_DIR="${LOCAL_DATA_DIR}/build"
COOKIES_DIR="${LOCAL_DATA_DIR}/cookies"
MDS_INPUT="${IO_DIR}/input"
MDS_OUTPUT="${IO_DIR}/output"
TEMP_DIR="/tmp/mdscode"

# Help menu columns width
WIDTH_1ST_OP=5
WIDTH_2ND_OP=28

# 9 => all, -lt 1 only errors
declare -g -i PRINT_MSG_LEVEL=9

function create_common_files() {
    mkdir -p "${TEMP_DIR}"
    mkdir -p "${LOCAL_DATA_DIR}"
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${IO_DIR}"
    mkdir -p "${TEST_DIR}"
    mkdir -p "${COOKIES_DIR}"
    touch "${MDS_INPUT}" "${MDS_OUTPUT}"
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

function set_shell_colors() {
    if [[ "${USE_COLOR}" == Y ]]
    then
        RED='\e[1;31m'
        GREEN='\e[1;32m'
        GREEN_DARK='\e[0;32m'
        YELLOW='\e[1;33m'
        BROWN='\e[0;33m'
        BLUE='\e[1;34m'
        BLUEG='\e[1;5;34m'
        PURPLE='\e[1;35m'
        PURPLEG='\e[1;5;35m'
        CYAN='\e[1;36m'
        CYAN_DARK='\e[0;36m'
        BLK='\e[0;0m'
    fi
}

function print_stacktrace() {
    if [[ "${PRINT_STACKTRACE}" == Y ]]
    then
        for ((i=1; i<${#BASH_SOURCE[@]}; i+=1))
        do
            printf "${YELLOW}${FUNCNAME[${i}]}${BROWN}...${GREEN}$(basename ${BASH_SOURCE[${i}]}):${CYAN}${BASH_LINENO[${i}]}${BLK}\n" >&2
        done
    fi
}

function cout() {
    local color=$1
    shift
    local messsage="$@"
    case ${color} in
        red|error)
            echo -e "${BLUE}[${RED}ERROR${BLUE}]${BLK} ${messsage}" >&2
            print_stacktrace
            exit 1
        ;;
        fault) # Non fatal error, not used for far was it was planned at the beginning
            [ ${PRINT_MSG_LEVEL} -gt 0 ] && echo -e "${BLUE}[${PURPLE}FAULT${BLUE}]${BLK} ${messsage}" >&2
            return 1
        ;;
        debug)
            [ ${PRINT_MSG_LEVEL} -gt 1 ] && echo -e "${BLUE}[${PURPLE}DEBUG${BLUE}]${BLK} ${messsage}" >&2
        ;;
        green|success)
            [ ${PRINT_MSG_LEVEL} -gt 8 ] && echo -e "${BLUE}[${GREEN}SUCCESS${BLUE}]${BLK} ${messsage}" >&2
        ;;
        yellow|warning)
            [ ${PRINT_MSG_LEVEL} -gt 2 ] && echo -e "${BLUE}[${YELLOW}WARNING${BLUE}]${BLK} ${messsage}" >&2
        ;;
        blue|info)
            [ ${PRINT_MSG_LEVEL} -gt 5 ] && echo -e "${BLUE}[${CYAN}INFO${BLUE}]${BLK} ${messsage}" >&2
        ;;
    esac
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

function save_build_data() {
    # File's data
    local problem_build_dir="${BUILD_DIR}/${FILENAME}"
    local build_data_file="${problem_build_dir}/data.sh"
    mkdir -p "${problem_build_dir}"

    echo FULLNAME=\"${FILENAME}\" > "${build_data_file}"
    echo LANG=\"${FILETYPE}\" >> "${build_data_file}"
    echo FULLPATH="\"$(realpath ${FILEPATH}/${FILENAME})\"" >> "${build_data_file}"
    echo PROBLEM_ID="\"${PROBLEM_ID}\"" >> "${build_data_file}"
    echo PROBLEM_URL="\"${PROBLEM_URL}\"" >> "${build_data_file}"
    echo ONLINE_JUDGE="\"${ONLINE_JUDGE}\"" >> "${build_data_file}"

    [[ "${FILETYPE}" == java ]] && local bin_name=Main.class || local bin_name=run
    echo BINARY_PATH="\"${BUILD_DIR}/${FILENAME}/${bin_name}\"" >> "${build_data_file}"

    # File's compilation flags
    local build_flags_file="${BUILD_DIR}/${FILENAME}/flags.sh"
    case ${FILETYPE} in
        cpp)
            echo "export CXX_STANDARD=\"${CONFIGS_MAP['CXX_STANDARD']}\"" > "${build_flags_file}"
            echo "export CXXCOMPILER=\"${CONFIGS_MAP['CXXCOMPILER']}\"" >> "${build_flags_file}"
            echo "export CXX_FLAGS=\"${CONFIGS_MAP['CXX_FLAGS']}\"" >> "${build_flags_file}"
            ;;
        c)
            echo "export CCCOMPILER=\"${CONFIGS_MAP['CCCOMPILER']}\"" > "${build_flags_file}"
            echo "export CC_FLAGS=\"${CONFIGS_MAP['CC_FLAGS']}\"" >> "${build_flags_file}"
            ;;
        *)
            > "${build_flags_file}"
            ;;
    esac
}

function open_with_editor() {
    if [[ ${CONFIGS_MAP['OPEN_WITH_EDITOR']} == YES ]]
    then
        # Useful env variable to customize your editor
        export COMPETITIVE_MODE=Y
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
        if [[ ${days_diff} -ge ${CONFIGS_MAP['DAYS_BEFORE_DELETION']} ]]
        then
            rm -rf ${target_dir}/${files[${j}]} &> /dev/null
        fi
    done
}

function open_flags() {
    local path_to_file="${BUILD_DIR}/${FILENAME}/flags.sh"
    if [[ -f ${path_to_file} ]]
    then
        open_with_editor "${path_to_file}"
    else
        cout error "Flags file not found."
    fi
}

function open_data() {
    local path_to_file="${BUILD_DIR}/${FILENAME}/data.sh"
    if [[ -f ${path_to_file} ]]
    then
        open_with_editor "${path_to_file}"
    else
        cout error "Data file not found."
    fi
}

function get_file_extension() {
    local extension=$(echo ${@} | grep -o -e '\..*' | sed s/^\.//g)
    echo ${extension}
}

function separate_filepath_and_filename() {
    missing_argument_validation 2 ${1} ${2}
    local -n filename_ref=${1}
    local -n filepath_ref=${2}
    filepath_ref=$(echo "${filename_ref}" | grep -o -e '.*\/' | sed 's|/$||g')
    filename_ref=$(echo "${filename_ref}" | awk -F '/' '{print $NF}')
    if [[ -z ${filepath_ref} ]]
    then
        filepath_ref="."
    fi
}

function load_build_data() {
    local ignore_failure=${1:-NO}
    if [[ "${ignore_failure}" == NO && (! -f "${BUILD_DIR}/${FILENAME}/flags.sh" || ! -f "${BUILD_DIR}/${FILENAME}/data.sh") ]]
    then
        cout error "Build data is unavailable. Please, verify if filename is specified correctly."
    fi
    source "${BUILD_DIR}/${FILENAME}/flags.sh" > /dev/null 2>&1
    source "${BUILD_DIR}/${FILENAME}/data.sh" > /dev/null 2>&1
}

function delete_build_data() {
    if [[ -n "${FILENAME}" ]]
    then
        rm -rf "${BUILD_DIR}/${FILENAME}" > /dev/null 2>&1
    fi
}

function is_cmd_option() {
    if [[ -n $(printf "%s" "${1}" | grep -e '^-') ]]
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
	grep -o -e '^[0-9]\+$' <(echo ${arg}) &> /dev/null
    exit_is_zero $?
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

function enable_debug_if_specified() {
    local all_args=$@
    echo ${all_args} | grep -e '-x' > /dev/null 2>&1
    if [[ $(exit_is_zero $?) == YES ]]
    then
        set -x
    fi
}

function common_setup() {
    set_shell_colors
    create_common_files
    delete_old_files ${TEST_DIR}
    delete_old_files ${BUILD_DIR}
}

clock_start() {
   [[ ! -v __CALLS_COUNTER ]] && declare -g -i __CALLS_COUNTER=0 # Clock counter used as varname's suffix
   [[ ! -v __CLOCK_STACK ]] && declare -g -a __CLOCK_STACK=() # Stack containing internal clocks
   declare -g -i __clock_start_${__CALLS_COUNTER}=$(( $(date +%s%N) / 1000 )) # Start time in microseconds
   __CLOCK_STACK+=( __clock_start_${__CALLS_COUNTER} )
   __CALLS_COUNTER+=1
}

# @brief computes total time spend in a function
# the result can be found in __total_spend_time in microseconds
clock_end() {
    local -i __clock_end=$(( $(date +%s%N) / 1000 ))
    local __clock_start_var=${__CLOCK_STACK[-1]}
    __total_spend_time=$( echo "(${__clock_end} - ${!__clock_start_var}) / 1000000" | bc -l )
    printf -v __total_spend_time "%.6f" ${__total_spend_time}
    cout debug "Total time spend at <${YELLOW}${FUNCNAME[1]}${BLK}> is ${CYAN}${__total_spend_time}${BLK} seconds."
    unset __CLOCK_STACK[-1] # Pop last variable time as will not be used again
}

function display_help() {
    printf "Usage: mdscode [options] file...\n"
    printf "Options:\n"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -f "--type [type]" "Specify the file type (c,cpp,py,java). Default: cpp"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -n "--name [args...]" "Filename"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--ignore-rename" "Ignore applying naming convensions."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -c "--create" "Create file"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -b "--build" "Build the given source file (c,cpp,py,java)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--force-build" "Always try to build the given source file (c,cpp,py,java)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -e "--exec" "Executes last compiled file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--exer" "Executes last compiled file without redirecting errors to output file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -i "--io" "Choose the prefered IO type (I,O,IO). Default: IO"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -t "--test [default:0]" "Test last compiled source file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -a "--add-test [no tests]" "Add a test case for the specified file (IMPORTANT: filename must be specified)."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--set-test [nth test]" "Sets the input of the Nth test as input of \$MDS_INPUT. (IMPORTANT: filename must be specified)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--edit-test [nth test]" "Edit the nth test."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -g "--gui" "Run interactive mode with terminal GUI."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -u "--problem-url" "Create file based on provided url."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -s "--submit " "Submit last built file. (UVA Judge)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--edit-flags" "Edit compile flags."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--edit-data" "Edit build data."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" "" "--clear-cookies" "Delete cookies"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -x "--debug" "Self explained"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -h "--help" "Show this"
    printf "\nDeveloped by Jehú Jair Ruiz Villegas\n"
    printf "Contact: jehuruvj@gmail.com\n"
    exit 0
}
