#!/bin/bash

export JAVA_HOME="${CONFIGS_MAP['JAVA_HOME']}"
MENU_JAVA_TEMPLATES=()

function menu_java_configs() {
    local choice_java_setup=$(whiptail --title "Java Setup" --menu -- "" 18 200 10 \
    "Add test cases" "${TEST_CASES_ARE_SET}" \
    "Template" "${TEMPLATE}" \
    "Continue (create/open)" "" \
    "Close" "" 3>&1 1>&2 2>&3)

    if [ -n "${choice_java_setup}" ]
    then
        case ${choice_java_setup} in
            "Add test cases")
                test_cases_setup_menu ${FUNCNAME}
            ;;
            "Template")
                menu_templates ${FUNCNAME} MENU_JAVA_TEMPLATES
            ;;
            *)
                CREATION="Y"
                if [[ ${TEST_CASES_ARE_SET} == YES ]]
                then
                    SET_TEST_INDEX=0
                fi
            ;;
        esac
    else
        exit 1
    fi
}

function menu_java_setup() {
    preload_templates MENU_JAVA_TEMPLATES
    load_test_cases $(get_test_folder_name ${FILENAME})
    set_default_template ${FILETYPE}
    menu_java_configs
}
