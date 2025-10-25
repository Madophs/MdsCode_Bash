#!/bin/bash

JUDGES_DIR="${SRC_DIR}/judges"

source "${JUDGES_DIR}/uva.sh"
source "${JUDGES_DIR}/aceptaelreto.sh"

function set_problem_data_by_url() {
    ONLINE_JUDGE="$(echo "${PROBLEM_URL}" | grep -o -e '[a-z]\+\.\(com\|org\)')"
    case "${ONLINE_JUDGE}" in
        "onlinejudge.org")
            uva_parse_problem_data FILENAME PROBLEM_ID
            ;;
        "aceptaelreto.com")
            aer_parse_problem_data FILENAME PROBLEM_ID
            ;;
        *)
            cout error "Unknown online judge <${ONLINE_JUDGE}>"
            ;;
    esac
}

function set_test_cases_from_online_judge_url() {
    case "${ONLINE_JUDGE}" in
        "onlinejudge.org")
            uva_set_sample_test
            ;;
        "aceptaelreto.com")
            aer_set_sample_test
            ;;
        *)
            cout warning "Autoset sample tests for <${ONLINE_JUDGE}> are not implemented yet."
            ;;
    esac
}

function clear_cookies() {
    rm -f "${UVA_COOKIES_FILE}"
    rm -f "${AER_COOKIES_FILE}"
}

function submit_code() {
    case ${ONLINE_JUDGE} in
        "onlinejudge.org")
            uva_submit
            ;;
        "aceptaelreto.com")
            aer_submit
            ;;
        *)
            cout error "Unknown Online Judge <${ONLINE_JUDGE}>"
            ;;
    esac
}
