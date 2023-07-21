#!/bin/bash

UVA_BASE_URL="https://onlinejudge.org"
UVA_INDEX_URL=${UVA_BASE_URL}/index.php
UVA_LOGIN_URL="${UVA_INDEX_URL}?option=com_comprofiler&task=login"
UVA_COOKIES_FILE=${BUILD_DIR}/uva_cookies

function get_uva_hidden_params() {
    curl -f -L -s  ${UVA_BASE_URL} | grep -B8 'id=\"mod_login_remember\"' | awk '{print $3  $4}' | grep -v 'remember' | awk -F '[=\"]' '{print $3"="$6}' | tr '\n' '\&' | sed 's/\&$/\&remember=yes/g'
}

function already_logged() {
    curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_INDEX_URL} | grep -i register &> /dev/null
    any_error $?
}

function uva_login() {
    PARAMS=$(get_uva_hidden_params)
    USERNAME=$(whiptail --inputbox "Username:" 10 100 3>&1 1>&2 2>&3)
    PASSWORD=$(whiptail --passwordbox "Password:" 10 100 3>&1 1>&2 2>&3)

    if [[ -z ${USERNAME} || -z ${PASSWORD} ]]
    then
        cout danger "[ERROR] Empty fields"
        exit 1
    fi

    curl --cookie-jar ${UVA_COOKIES_FILE} -f -s -L --compressed -d "${PARAMS}&username=${USERNAME}&passwd=${PASSWORD}" ${UVA_LOGIN_URL} &> /dev/null
}

function uva_try_login() {
    ATTEMPTS=0
    while [[ $(already_logged) == "NO" ]]
    do
        if [[ ${ATTEMPTS} > 0 ]]
        then
            cout warning "Incorrect Username or Password, retry? (y/n)"
            read -n 1 OPT
            if [[ ${OPT} == 'n' || ${OPT} == 'N' ]]
            then
                exit 0
            fi
        fi
        uva_login
        ATTEMPTS=$(( ${ATTEMPTS} + 1 ))
    done

    if [[ ${ATTEMPTS} > 0 ]]
    then
        cout success "Login successfull!!!"
    fi
}

function uva_submit() {
    uva_try_login
}
