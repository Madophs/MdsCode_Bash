#!/bin/bash

CONFIGS_DIR=${SCRIPT_DIR}/configs
CONFIGS_FILE=${CONFIGS_DIR}/configure.in
declare -A CONFIGS_MAP=()

function is_valid_line() {
    local line=$1
    if [[ -z ${line} ]]
    then
        echo "NO"
        return 0
    fi

    echo "${line}" | grep -e '^[#]' > /dev/null 2>&1
    if [[ $(exit_is_zero $?) == YES ]]
    then
        echo "NO"
    else
        echo "YES"
    fi
}

function read_default_configs() {
    local varname
    local varvalue

    while read line;
    do
        if [[ $(is_valid_line "${line}") == YES ]]
        then
            varname=$(echo ${line} | grep -o -e '^[A-Z_]*')
            varvalue=$(echo ${line} | grep -o -e '=.*' | sed s/^=//g)
            CONFIGS_MAP+=(["${varname}"]="${varvalue}")
        fi
    done
} < ${CONFIGS_FILE}

function read_saved_flags() {
    local file_to_build
    if [[ -z ${1} ]]
    then
        file_to_build=$(get_last_source_file)
    else
        file_to_build=${1}
    fi
    source ${FLAGS_DIR}/${file_to_build}.sh > /dev/null 2>&1
}

function read_custom_configs() {
    declare -a configs_map_keys=(${!CONFIGS_MAP[*]})
    read_saved_flags ${1}
    local result
    local value
    for (( i=0; i < ${#configs_map_keys[*]}; i+=1 ))
    do
        result=$(env | grep -e "^${configs_map_keys[${i}]}")
        if [[ -n ${result} ]]
        then
            value=$(echo ${result} | grep -o -e '=.*' | sed s/^=//g)
            declare -g -A CONFIGS_MAP+=(["${configs_map_keys[${i}]}"]="${value}")
        fi
    done
}

function load_configs() {
    read_default_configs
    read_custom_configs
}
