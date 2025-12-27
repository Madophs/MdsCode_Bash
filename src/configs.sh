#!/bin/bash

CONFIGS_DIR="${SCRIPT_DIR}/configs"
CONFIGS_FILE="${CONFIGS_DIR}/configure.in"
declare -A CONFIGS_MAP=()

function read_default_configs() {
    local line='' varname='' varvalue=''
    while read line;
    do
        [[ -z "${line}" || "${line}" =~ ^\ *# ]] && continue # Skip empty lines and comments
        varname="${line%%=*}"
        varvalue="${line##${varname}=}"
        CONFIGS_MAP+=(["${varname}"]="${varvalue}")
    done
} < "${CONFIGS_FILE}"

function read_custom_configs() {
    declare -a configs_map_keys=(${!CONFIGS_MAP[*]})
    local varname
    for varname in ${configs_map_keys[@]}
    do
        if [[ "${!varname@a}" == *x* ]]
        then
            CONFIGS_MAP+=(["${varname}"]="${!varname}")
        fi
    done
}

function load_configs() {
    read_default_configs
    read_custom_configs
}
