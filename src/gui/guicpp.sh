#!/bin/bash

AVAILABLE_CPP_STANDARDS=("-std=c++2a" "" "-std=c++17" "" "-std=c++14" "" "-std=c++11" "" "-std=c++98" "")
MENU_CPP_FLAGS=()
MENU_CPP_TEMPLATES=()

function set_global_cpp_variables() {
    declare -g CPP_STANDARD="${CONFIGS_MAP['CXX_STANDARD']}"
    declare -g CPP_FLAGS=" ${CONFIGS_MAP['CXX_FLAGS']}"
    declare -g -a AVAILABLE_CPP_FLAGS=(${CONFIGS_MAP['CXX_AVAILABLE_FLAGS']})
}

function preload_cpp_flags() {
    MENU_CPP_FLAGS=()
    local index=0
    local item
    for item in "${AVAILABLE_CPP_FLAGS[@]}"
    do
        MENU_CPP_FLAGS+=(${index})
        MENU_CPP_FLAGS+=(${item})
        printf "%s" "${CPP_FLAGS}" | grep -w -e "${item}" > /dev/null 2>&1
        if [[ $(exit_is_zero $?) == YES ]]
        then
            MENU_CPP_FLAGS+=(ON)
        else
            MENU_CPP_FLAGS+=(OFF)
        fi
        index=$(( index + 1 ))
    done
}

function menu_cpp_standards() {
    CPP_STANDARD=$(whiptail --title "C++ Standard" --menu -- "" 18 100 10 "${AVAILABLE_CPP_STANDARDS[@]}" 3>&1 1>&2 2>&3)
    if [ -n "${CPP_STANDARD}" ]
    then
        CONFIGS_MAP['CXX_STANDARD']="${CPP_STANDARD[@]}"
        menu_cpp_configs
    else
        exit 1
    fi
}

function menu_cpp_flags() {
    local choices=$(whiptail --title "Select your flags" --separate-output --checklist -- "" 18 55 10 ${MENU_CPP_FLAGS[@]} 3>&1 1>&2 2>&3)
    if [ -n "${choices}" ]
    then
        local size=$(( ${#MENU_CPP_FLAGS[@]} / 3 ))
        for (( i=1; i <= ${size}; i+=1 ))
        do
            MENU_CPP_FLAGS[$(( ${i} * 3 - 1 ))]=OFF
        done

        CPP_FLAGS=
        local item
        for item in ${choices}
        do
            CPP_FLAGS="${CPP_FLAGS} ${AVAILABLE_CPP_FLAGS[${item}]}"
            MENU_CPP_FLAGS[$(( ( (${item} + 1) * 3) - 1 ))]=ON
        done
        CONFIGS_MAP['CXX_FLAGS']="${CPP_FLAGS[@]}"
        menu_cpp_configs
    else
        exit 1
    fi
}

function menu_cpp_configs() {
    local choice_cpp_setup=$(whiptail --title "C++ Setup" --menu -- "" 18 200 10 \
    "C++ Standard " "${CPP_STANDARD}" \
    "Flags " "${CPP_STANDARD}${CPP_FLAGS}" \
    "Template" "${TEMPLATE}" \
    "Add test cases" "${TEST_CASES_ARE_SET}" \
    "Continue (create/open)" "" \
    "Close" "" 3>&1 1>&2 2>&3)

    if [ -n "${choice_cpp_setup}" ]
    then
        case ${choice_cpp_setup} in
            "C++ Standard ")
                menu_cpp_standards
            ;;
            "Flags ")
                menu_cpp_flags
            ;;
            "Template")
                menu_templates ${FUNCNAME} MENU_CPP_TEMPLATES
            ;;
            "Add test cases")
                test_cases_setup_menu ${FUNCNAME}
            ;;
            "Continue (create/open)")
                CREATION="Y"
                if [[ ${TEST_CASES_ARE_SET} == YES ]]
                then
                    SET_TEST_INDEX=0
                fi
            ;;
            *)
                exit 0
            ;;
        esac
    else
        exit 1
    fi
}

function menu_cpp_setup() {
    set_global_cpp_variables
    preload_cpp_flags
    preload_templates MENU_CPP_TEMPLATES
    load_test_cases $(get_test_folder_name ${FILENAME})
    set_default_template ${FILETYPE}
    menu_cpp_configs
}
