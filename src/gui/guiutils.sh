#!/bin/bash

function exit_if_whiptail_not_installed() {
    if [[ ! -x $(which whiptail) ]]
    then
        cout error "Please install whiptail package to use gui mode"
    fi
}

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

# https://askubuntu.com/questions/776831/whiptail-change-background-color-dynamically-from-magenta
function set_newt_colors() {
    if [[ $(is_vim_the_father) == YES ]]
    then
        export NEWT_COLORS='
            root=black,black
            window=lightgray,lightgray
            border=white,black
            entry=white,black
            textbox=white,black
            button=black,red
            title=white,black
            checkbox=white,black
            actsellistbox=white,black
        '
    else
        export NEWT_COLORS='
            root=black,black
            window=lightgray,lightgray
            border=white,gray
            entry=white,gray
            textbox=white,gray
            button=black,red
            title=white,gray
            checkbox=white,gray
        '
    fi
}
