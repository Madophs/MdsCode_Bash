#!/bin/bash

SRC_DIR=${SCRIPT_DIR}/src
RES_DIR=${SCRIPT_DIR}/res
TEMPLATES_DIR=${RES_DIR}/templates
FILENAME=""
TEMP_FILE="" # Temporal file
TEMP_DIR="/tmp/mdscode"
BUILD_DIR=${SCRIPT_DIR}/build
IO_DIR=${RES_DIR}/io
IO_ARGS=""

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

common_setup
