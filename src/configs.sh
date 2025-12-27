#!/bin/bash

CONFIGS_DIR="${SCRIPT_DIR}/configs"
CONFIGS_FILE="${CONFIGS_DIR}/configure.in"
declare -A CONFIGS_MAP=()

function read_default_configs() {
    local line='' varname='' varvalue=''
    local -i equals_index=0
    while read line;
    do
        [[ -z "${line}" || "${line}" =~ ^\ *# ]] && continue # Skip empty lines and comments
        equals_index=$(expr index "${line}" "=")
        varname="${line:0:$((equals_index-1))}"
        varvalue="${line:${equals_index}}"
        CONFIGS_MAP+=(["${varname}"]="${varvalue}")
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
