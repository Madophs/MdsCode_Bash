#!/bin/bash

SRC_DIR=${SCRIPT_DIR}/src
RES_DIR=${SCRIPT_DIR}/res
TEMPLATES_DIR=${RES_DIR}/templates
FILENAME=""
TEMP_FILE="" # Temporal file
TEMP_DIR="/tmp/mdscode"
BUILD_DIR=${SCRIPT_DIR}/build
IO_DIR=${RES_DIR}/io
TEST_DIR=${RES_DIR}/tests
NO_TEST=0
CREATE_TESTS="N"
TESTING="N"
IO_ARGS=""
WIDTH_1ST_OP=5
WIDTH_2ND_OP=20

# Global variables for naming conventions
# CASETYPE
# UCWORDS uppercase the first letter of every word
# UPPERCASE Y LOWERCASE
CASETYPE="UCWORDS"
WHITESPACE_REPLACE="_"

# C/C++ variables
CXXCOMPILER="g++"
MDS_CXX_FLAGS="-std=c++17 -O0 -Wall -Wextra -g"
CCCOMPILER="gcc"
MDS_CC_FLAGS="-Wall -Wextra -g"

function common_setup() {
    mkdir -p "/tmp/mdscode"
    mkdir -p ${BUILD_DIR}
    mkdir -p ${IO_DIR}
    mkdir -p ${TEST_DIR}
    touch ${IO_DIR}/input ${IO_DIR}/output
}

function missing_argument_validation() {
    ARG=${1}
    if [[ -z ${2} ]]
    then
        echo "[ERROR] missing argument for \"${ARG}\""
        exit 1
    elif [[ -n $(echo ${2} | grep -e "^-") ]]
    then
        echo "[ERROR] Invalid argument \"${2}\""
        exit 1
    fi
}

function is_digit() {
    ARG=${1}
	grep -o -e '^[0-9]*$' <(echo ${ARG}) &> /dev/null
    if [[ $? != 0 ]]
    then
        echo "[ERROR] Invalid value ${ARG}"
        exit 1
    fi
}

function cout() {
    COLOR=$1
    MESSAGE=$2
    case $COLOR in
        red|error|danger)
        echo -e "\e[1;31m${MESSAGE} \e[0m"
        ;;
        green|success)
        echo -e "\e[1;32m${MESSAGE} \e[0m"
        ;;
        yellow|warning)
        echo -e "\e[1;33m${MESSAGE} \e[0m"
        ;;
        blue|info)
        echo -e "\e[1;34m${MESSAGE} \e[0m"
        ;;
    esac
}

function display_help() {
    printf "Usage: mdscode [options] file...\n"
    printf "Options:\n"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -b "--build [file]" "Build the given source file (c,cpp,py,java)"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -e "--exec" "Executes the previous compiled file."
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -i "--io" "Choose the prevefered IO type (I,O,IO). Default: IO"
    printf "%-${WIDTH_1ST_OP}s %-${WIDTH_2ND_OP}s %s\n" -t "--test [no tests]" "Test the last compiled bin. If a parameter is specified (optional) then asks for the tests."
    printf "\nDeveloped by Jehú Jair Ruiz Villegas\n"
    printf "Contact: jehuruvj@gmail.com\n"
}

common_setup
