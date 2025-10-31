#!/bin/bash

CONFIGS_DIR="${SCRIPT_DIR}/configs"
CONFIGS_FILE="${CONFIGS_DIR}/configure.in"
declare -A CONFIGS_MAP=()

function is_valid_line() {
    local line=$1
    if [[ -z ${line} ]]
    then
        echo "NO"
    else
        echo "${line}" | grep -e '^[#]' > /dev/null 2>&1
        exit_is_not_zero $?
    fi
}

function read_default_configs() {
    while read line;
    do
        if [[ $(is_valid_line "${line}") == YES ]]
        then
            local varname=$(echo ${line} | grep -o -e '^[A-Z_]*')
            local varvalue=$(echo ${line} | grep -o -e '=.*' | sed s/^=//g)
            CONFIGS_MAP+=(["${varname}"]="${varvalue}")
        fi
    done
} < "${CONFIGS_FILE}"

function read_custom_configs() {
    declare -a configs_map_keys=(${!CONFIGS_MAP[*]})
    for (( i=0; i < ${#configs_map_keys[@]}; i+=1 ))
    do
        local result=$(env | grep -e "^${configs_map_keys[${i}]}")
        if [[ -n ${result} ]]
        then
            local value=$(echo "${result}" | grep -o -e '=.*' | sed s/^=//g)
            CONFIGS_MAP+=(["${configs_map_keys[${i}]}"]="${value}")
        fi
    done
}

function load_configs() {
    read_default_configs
    read_custom_configs
}
