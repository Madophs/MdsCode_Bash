#!/bin/bash

source "${GIT_REPOS}/MdsCode_Bash/src/common.sh"
AER_BASE_URL="https://aceptaelreto.com"
AER_LOGIN_URL="${AER_BASE_URL}/bin/login.php"
AER_LOGOUT_URL="${AER_BASE_URL}/bin/logout.php"
AER_SUBMIT_URL="${AER_BASE_URL}/bin/submitproblem.php"
AER_COOKIES_FILE="${COOKIES_DIR}/aer_cookies"

function aer_parse_problem_data() {
    missing_argument_validation 2 ${1} ${2}
    declare -n filename=${1}
    declare -n problem_id=${2}
    local raw_name=$(curl -L -s "${PROBLEM_URL}" | grep -e 'setDocumentTitle' | awk -F '[/]' '{print $2}')
    filename=$(echo "${raw_name}" | sed 's/ *[0-9]\+ - //g')
    problem_id=$(echo "${raw_name}" | grep -o -e '[0-9]\+')
}

function aer_is_logged() {
    curl -X GET --cookie "${AER_COOKIES_FILE}" -f -s -L --compressed "${AER_BASE_URL}" 2> /dev/null | grep -e 'dropdownLogin' &> /dev/null
    exit_is_not_zero $?
}

function aer_login() {
    local username=$(whiptail --inputbox "Username:" 10 100 3>&1 1>&2 2>&3)
    local password=$(whiptail --passwordbox "Password:" 10 100 3>&1 1>&2 2>&3)

    if [[ -z ${username} || -z ${password} ]]
    then
        cout error "Empty fields"
    fi
    curl -X POST --cookie-jar ${AER_COOKIES_FILE} -f -s -L --compressed -d "loginForm_username=${username}&loginForm_password=${password}&loginForm_RememberMeField=1" ${AER_LOGIN_URL} &> /dev/null
}

function aer_logout() {
    curl -X POST --cookie-jar "${AER_COOKIES_FILE}" -f -s -L --compressed -d "logout_currentPage=/" ${AER_LOGOUT_URL} &> /dev/null
}

function aer_try_login() {
    if [[ "$(aer_is_logged)" == YES ]]
    then
        return
    fi

    local -i max_attempts=3
    local -i attempts=0
    while (( ${attempts} < ${max_attempts} ))
    do
        aer_login
        if [[ "$(aer_is_logged)" == NO ]]
        then
            whiptail --title "Failed login" --yesno "Wrong password or username, try again?" 10 100 || cout error "Failed to login!"
        else
            return
        fi
        attempts+=1
    done
    cout error "Failed to login, please check your credentials"
}

function aer_submit() {
    aer_try_login
    local currentPageInput="/problem/send.php?id=116"
    local sentCodeInput="sentCodeFile"
    local catInput="-1"
    local idInput="116"
    local languageInput="CPP"
    local solutionFile="/home/madophs/Documents/git/Competitive-Programming/Acepta el reto/Volumen 1/Hola_mundo.cpp"
    curl -X POST -v -f -s -L -w '%{url_effective}' --compressed --cookie "${AER_COOKIES_FILE}" --cookie-jar "${AER_COOKIES_FILE}" -H "Content-Type: multipart/form-data" \
        -F currentPage=${currentPageInput} -F cat=${catInput} -F sentCode=${sentCodeInput} -F comment="" -F immediateCode="" \
        -F id=${idInput} -F language=${languageInput} -F "inputFile=@${solutionFile}" ${AER_SUBMIT_URL} &> /dev/null
}
