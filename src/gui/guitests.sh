#!/bin/bash

TEST_CASES_SET=("New test" "" "Go back" "")
TEST_CASES_ARE_SET="NO"

function load_test_cases() {
    missing_argument_validation 1 ${1}
    TEST_CASES_ARE_SET="NO"
    local tests_folder=${1}
    local test_src_folder=${TEST_DIR}/${tests_folder}
    if [[ ! -d ${test_src_folder} ]]
    then
        return
    fi
    local test_cases_list=($(ls -l ${test_src_folder} | tail -n +2 | awk '{print $NF}' | grep -o -e '[0-9]*' | sort | uniq | paste -s -d ' '))
    TEST_CASES_SET=()
    for (( i=0; i < ${#test_cases_list[@]}; i+=1 ))
    do
        declare -g TEST_CASES_SET+=("Test ${test_cases_list[${i}]}" "")
        TEST_CASES_ARE_SET="YES"
    done
    TEST_CASES_SET+=("New test" "")
    TEST_CASES_SET+=("Go back" "")
}

function delete_test() {
    local test_src_folder_name=${1}
    local test_src_folder=${TEST_DIR}/${1}
    local to_delete=${3}
    whiptail --title "Delete test case" --yesno --defaultno "Are you sure to delete Test #${to_delete}?" 20 60 3>&1 1>&2 2>&3
    if [[ $(exit_is_zero $?) == YES ]]
    then
        rm -f ${test_src_folder}/test_input_${to_delete}.txt &> /dev/null
        rm -f ${test_src_folder}/test_output_${to_delete}.txt &> /dev/null
        align_tests "${test_src_folder}"
        load_test_cases "${test_src_folder_name}"
    fi
}

function test_cases_setup_menu() {
    local src_folder_name=$(echo ${FILENAME} | sed 's/\./_/g')
    local testcase_choice=$(whiptail --title "Test cases" --menu -- "" 18 100 10 "${TEST_CASES_SET[@]}" 3>&1 1>&2 2>&3)
    if [[ $(exit_is_zero $?) == YES ]]
    then
        case ${testcase_choice} in
            "New test")
                mdscode -a 1 "${FILENAME}"
                load_test_cases ${src_folder_name}
                test_cases_setup_menu
            ;;
            "Go back")
                menu_cpp_setup
            ;;
            *)
                delete_test ${src_folder_name} ${testcase_choice}
                test_cases_setup_menu
            ;;
        esac
    else
        exit 1
    fi
}
