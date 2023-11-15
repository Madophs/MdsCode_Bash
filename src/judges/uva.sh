#!/bin/bash

UVA_BASE_URL="https://onlinejudge.org"
UVA_INDEX_URL=${UVA_BASE_URL}/index.php
UVA_LOGIN_URL="${UVA_INDEX_URL}?option=com_comprofiler&task=login"
UVA_COOKIES_FILE=${BUILD_DIR}/uva_cookies
UVA_SUBMIT_URL="${UVA_INDEX_URL}?option=com_onlinejudge&Itemid=25&page=save_submission"

function uva_get_hidden_params() {
    curl -f -L -s  ${UVA_BASE_URL} | grep -B8 'id=\"mod_login_remember\"' | awk '{print $3  $4}' | grep -v 'remember' | awk -F '[=\"]' '{print $3"="$6}' | tr '\n' '\&' | sed 's/\&$/\&remember=yes/g'
}

function uva_already_logged() {
    curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_INDEX_URL} | grep -i register &> /dev/null
    exit_is_not_zero $?
}

function uva_login() {
    local params=$(uva_get_hidden_params)
    local username=$(whiptail --inputbox "Username:" 10 100 3>&1 1>&2 2>&3)
    local password=$(whiptail --passwordbox "Password:" 10 100 3>&1 1>&2 2>&3)

    if [[ -z ${username} || -z ${password} ]]
    then
        cout error "Empty fields"
    fi

    curl --cookie-jar ${UVA_COOKIES_FILE} -f -s -L --compressed -d "${params}&username=${username}&passwd=${password}" ${UVA_LOGIN_URL} &> /dev/null
}

function uva_try_login() {
    local attempts=0
    while [[ $(uva_already_logged) == NO ]]
    do
        if [[ ${attempts} > 0 ]]
        then
            cout warning "Incorrect Username or Password, retry? (y/n)"
            read -n 1 opt
            if [[ ${opt} == 'n' || ${opt} == 'N' ]]
            then
                exit 0
            fi
        fi
        uva_login
        attempts=$(( ${attempts} + 1 ))
    done

    if [[ ${attempts} > 0 ]]
    then
        cout success "Login successfull!!!"
    fi
}

function uva_get_problem_id() {
    echo "${1}" | grep -o -e '[0-9]*\.' | sed 's/.$//g'
}

function uva_get_lang_id() {
    local lang=$(echo "${1}" | egrep -o -e 'cpp$|py$|rs$|c$|java$')
    case ${lang} in
        c)
            echo 1
            ;;
        java)
            echo 2
            ;;
        cpp)
            echo 5
            ;;
        py)
            echo 6
            ;;
        *)
            cout error "Unknown language ${lang}"
            ;;
    esac
}

function uva_submit() {
    uva_try_login

    if [[ -z ${ORIGINAL_SOURCE} ]]
    then
        source ${BUILD_INFO}
    fi

    local problem_id=$(uva_get_problem_id "${ORIGINAL_SOURCE}")
    local language_id=$(uva_get_lang_id "${ORIGINAL_SOURCE}")

    curl -X POST -f -L -s -w '%{url_effective}' --compressed --cookie ${UVA_COOKIES_FILE} --cookie-jar ${UVA_COOKIES_FILE} -H "Content-Type: multipart/form-data" \
        -F localid=${problem_id}  -F language=${language_id} -F "codeupl=@${ORIGINAL_SOURCE}" ${UVA_SUBMIT_URL} &> /dev/null

    if [[ $(exit_is_zero $?) == YES ]]
    then
        cout success "File uploaded!!!"
    else
        cout danger "Something went wrong :("
    fi
}
