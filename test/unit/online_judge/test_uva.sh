#!/bin/bash

source ../../../mdscode
source ../helper_functions.sh

function test_uva_file_creation_by_problem_url() {
    local problem_url="https://onlinejudge.org/index.php?option=com_onlinejudge&Itemid=8&category=17&page=show_problem&problem=1441"
    local expected_filename="Robot_Maps_10500.cpp"
    helper_file_creation_by_url "${problem_url}" "${expected_filename}"

    problem_url="https://onlinejudge.org/external/115/11581.pdf"
    expected_filename="Grid_Successors_11581.cpp"
    helper_file_creation_by_url "${problem_url}" "${expected_filename}"
}
