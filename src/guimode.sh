#!/bin/bash

source "${SRC_DIR}/gui/guiutils.sh"
source "${SRC_DIR}/gui/guitests.sh"
source "${SRC_DIR}/gui/guicpp.sh"
source "${SRC_DIR}/gui/guijava.sh"

AVAILABLE_LANGUAGES=("C++" "" "C Language" "" "Java" "" "Python" "" "Rust" "")

function input_filename() {
    if [[ -n "${PROBLEM_URL}" ]]
    then
        set_problem_data_by_url
    fi

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

function start_gui() {
    clear
    exit_if_whiptail_not_installed
    set_newt_colors
    start_wizard
}
