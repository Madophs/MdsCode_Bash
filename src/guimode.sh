#!/bin/bash

source ${SRC_DIR}/gui/guitests.sh
source ${SRC_DIR}/gui/guicpp.sh

AVAILABLE_LANGUAGES=("C++" "" "C Language" "" "Java" "" "Python" "" "Rust" "")

function is_vim_the_father() {
    CHILD=$(ps $$ | tail -n 1 | awk '{print $1}')
    PARENT=
    while true
    do
        PARENT=$(ps -o ppid -p ${CHILD} | tail -n 1 | awk '{print $1}')
        COMMAND=$(ps -o command -p ${PARENT} | tail -n 1 | awk -F / '{print $NF}' | awk '{print $1}')
        if [[ ${PARENT} == 1 ]]
        then
            echo "NO"
            break
        elif [[ ${COMMAND} == "vim" || ${COMMAND} == "nvim" ]]
        then
            echo "YES"
            break
        fi
        CHILD=${PARENT}
    done
}

# https://askubuntu.com/questions/776831/whiptail-change-background-color-dynamically-from-magenta
function set_newt_colors() {
    USING_VIM=$(is_vim_the_father)
    if [[ ${USING_VIM} == "YES" ]]
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

function input_filename() {
    FILENAME=$(whiptail --inputbox "Filename:" 10 100 "${FILENAME}" 3>&1 1>&2 2>&3)
    if [[ -z ${FILENAME} ]]
    then
        cout error "Exiting: you didn't specify a filename."
    fi
    apply_naming_convention FILENAME ${FILETYPE}
}

function show_menu_language_configs() {
    case ${FILETYPE} in
        cpp)
            menu_cpp_setup
            ;;
    esac
}

function menu_choose_language() {
    local language=$(whiptail --title "Choose your weapon" --menu "" 18 100 10 "${AVAILABLE_LANGUAGES[@]}" 3>&1 1>&2 2>&3)
    if [[ -n "${language}" ]]
    then
        FILETYPE=$(get_filetype_by_language ${language})
    else
        exit 1
    fi
}

function start_wizard() {
    menu_choose_language
    input_filename
    show_menu_language_configs
    save_flags
}

function exit_if_whiptail_not_installed() {
    if [[ ! -x $(which whiptail) ]]
    then
        cout error "Please install whiptail package to use gui mode"
    fi
}

function start_gui() {
    exit_if_whiptail_not_installed
    set_newt_colors
    start_wizard

    GUI="N"
    # Let's keep it simple and run the command again with the params
    ${SCRIPT_DIR}/mdscode -n "${FILENAME}" -f ${FILETYPE} -p ${TEMPLATE}
}
