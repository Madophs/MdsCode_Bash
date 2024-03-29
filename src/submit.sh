#!/bin/bash

JUDGES_DIR=${SRC_DIR}/judges

source ${JUDGES_DIR}/uva.sh

function submit_code() {
    case ${ONLINE_JUDGE} in
        UVA|uva)
            uva_submit
            ;;
        *)
            cout error "Unknown Online Judge"
            ;;
    esac
}
