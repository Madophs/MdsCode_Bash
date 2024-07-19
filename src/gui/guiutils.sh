#!/bin/bash

function preload_templates() {
    missing_argument_validation 1 ${1}
    declare -n template_list=${1}
    local available_templates=($(ls -l ${TEMPLATES_DIR}/*${FILETYPE} | awk -F '/' '{print $NF}'))
    local item
    template_list=()
    for item in "${available_templates[@]}"
    do
        template_list+=(${item})
        template_list+=("")
    done
}

function menu_templates() {
    missing_argument_validation 2 ${1} ${2}
    local func_ref=${1}
    declare -n templates_ref=${2}
    local template_choice=$(whiptail --title "Templates" --menu -- "" 18 100 10 "${templates_ref[@]}" 3>&1 1>&2 2>&3)
    if [ -n "${template_choice}" ]
    then
        TEMPLATE=${template_choice}
        ${func_ref}
    else
        exit 1
    fi
}
