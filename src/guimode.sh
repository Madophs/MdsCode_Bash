#!/bin/bash

source ${SRC_DIR}/gui/guiutils.sh
source ${SRC_DIR}/gui/guitests.sh
source ${SRC_DIR}/gui/guicpp.sh
source ${SRC_DIR}/gui/guijava.sh

AVAILABLE_LANGUAGES=("C++" "" "C Language" "" "Java" "" "Python" "" "Rust" "")

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

function input_filename() {
    if [[ -z ${FILENAME} ]]
    then
        FILENAME=$(whiptail --inputbox "Filename:" 10 100 "${FILENAME}" 3>&1 1>&2 2>&3)
        if [[ -z ${FILENAME} ]]
        then
            cout error "Exiting: you didn't specify a filename."
        fi
    fi
}

function show_menu_language_configs() {
    case ${FILETYPE} in
        cpp)
            menu_cpp_setup
            ;;
        java)
            menu_java_setup
            ;;
    esac
}

function menu_choose_language() {
    FILETYPE=$(get_file_extension ${FILENAME})
    if [[ -z ${FILETYPE} ]]
    then
        local language=$(whiptail --title "Choose your weapon" --menu "" 18 100 10 "${AVAILABLE_LANGUAGES[@]}" 3>&1 1>&2 2>&3)
        if [[ -n "${language}" ]]
        then
            FILETYPE=$(get_filetype_by_language ${language})
        else
            exit 1
        fi
    fi
}

function file_creation_wizard() {
    input_filename
    menu_choose_language
    apply_naming_convention FILENAME ${FILETYPE}
}

function start_wizard() {
    file_creation_wizard
    show_menu_language_configs
}

function exit_if_whiptail_not_installed() {
    if [[ ! -x $(which whiptail) ]]
    then
        cout error "Please install whiptail package to use gui mode"
    fi
}

function start_gui() {
    clear
    exit_if_whiptail_not_installed
    set_newt_colors
    start_wizard
}
