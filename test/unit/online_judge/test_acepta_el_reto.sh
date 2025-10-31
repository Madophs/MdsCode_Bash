#!/bin/bash

source ../../../mdscode
source ../helper_functions.sh

function test_aer_file_creation_by_problem_url() {
    local problem_url="https://aceptaelreto.com/problem/statement.php?id=463"
    local expected_filename="Tomas_Ineditas_463.cpp"
    helper_file_creation_by_url "${problem_url}" "${expected_filename}"
}
