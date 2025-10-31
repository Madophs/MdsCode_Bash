#!/bin/bash

source "${GIT_REPOS}/MdsCode_Bash/src/common.sh"
AER_BASE_URL="https://aceptaelreto.com"
AER_LOGIN_URL="${AER_BASE_URL}/bin/login.php"
AER_LOGOUT_URL="${AER_BASE_URL}/bin/logout.php"
AER_SUBMIT_URL="${AER_BASE_URL}/bin/submitproblem.php"
AER_LAST_SUBMISSIONS="${AER_BASE_URL}/user/lastsubmissions.php"
AER_COOKIES_FILE="${COOKIES_DIR}/aer_cookies"
AER_USER_ID=""

function aer_parse_problem_data() {
    missing_argument_validation 2 ${1} ${2}
    declare -n filename=${1}
    declare -n problem_id=${2}
    local raw_name=$(curl -L -s "${PROBLEM_URL}" | grep -e 'setDocumentTitle' | awk -F '[/]' '{print $2}')
    filename=$(echo "${raw_name}" | sed 's/ *[0-9]\+ - //g')
    problem_id=$(echo "${raw_name}" | grep -o -e '[0-9]\+')
}

function aer_set_sample_test() {
    local sample_test_link=$(curl -L -s "${PROBLEM_URL}" | grep -o -e 'https:.\+\.zip')
    local zip_filename=$(echo "${sample_test_link}" | awk -F '/' '{print $NF}')

    if [[ ! -f "${TEMP_DIR}/${zip_filename}" ]]
    then
        wget -q "${sample_test_link}" -P "${TEMP_DIR}"
    fi
    unzip -qq -o "${TEMP_DIR}/${zip_filename}" -d "${TEMP_DIR}"

    local test_src_folder="${TEST_DIR}/${FULLNAME}"
    mkdir -p "${test_src_folder}"
    mv "${TEMP_DIR}/sample.in" "${test_src_folder}/test_input_0.txt"
    mv "${TEMP_DIR}/sample.out" "${test_src_folder}/test_output_0.txt"
    SET_TEST_INDEX=0
}

function aer_is_logged() {
    curl -X GET --cookie "${AER_COOKIES_FILE}" -f -s -L --compressed "${AER_BASE_URL}" 2> /dev/null | grep -e 'dropdownLogin' &> /dev/null
    exit_is_not_zero $?
}

function aer_set_user_id() {
    AER_USER_ID=$(curl -X GET --cookie "${AER_COOKIES_FILE}" -f -s -L --compressed "${AER_LAST_SUBMISSIONS}" | grep -e 'currentUser' | grep -o -e 'id:[0-9]\+' | grep -o -e '[0-9]\+')
    if [[ -z ${AER_USER_ID} ]]
    then
        cout error "Failed to set AER user id"
    fi
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

function aer_verdict() {
    local -i datetime_before_submission=${1}
    local -i MAX_TRIES=10
    local -i counter=0

    local last_submission=$(curl -L -s "${AER_BASE_URL}/ws/user/${AER_USER_ID}/submissions" | sed 's/},{/\n/g' | grep -m 1 -e "\"num\":${PROBLEM_ID}")
    while [[ -z "${last_submission}" ]]
    do
        if (( ${counter} >= ${MAX_TRIES} ))
        then
            cout error "Timeout: no submission was found for problem <${PROBLEM_ID}>, datetime <${datetime_before_submission}>"
        fi

        local last_submission=$(curl -L -s "${AER_BASE_URL}/ws/user/${AER_USER_ID}/submissions" | sed 's/},{/\n/g' | grep -m 1 -e "\"num\":${PROBLEM_ID}")
        counter+=1
        sleep 3
    done

    counter=0
    local -i datetime_last_submission=$(echo "${last_submission}" | grep -o -e '[0-9]\{10\}')
    while (( datetime_last_submission < datetime_before_submission ))
    do
        cout debug "${datetime_last_submission} ${datetime_before_submission}"
        if (( ${counter} >= ${MAX_TRIES} ))
        then
            cout error "Timeout: unable to find submission after datetime <${datetime_before_submission}> for problem <${PROBLEM_ID}>"
        fi

        local last_submission=$(curl -L -s "${AER_BASE_URL}/ws/user/${AER_USER_ID}/submissions" | sed 's/},{/\n/g' | grep -m 1 -e "\"num\":${PROBLEM_ID}")
        local -i datetime_last_submission=$(echo "${last_submission}" | grep -o -e '[0-9]\{10\}')
        counter+=1
        sleep 3
    done

    cout info "Waiting for verdict"
    for i in $(seq ${MAX_TRIES})
    do
        local last_submission=$(curl -L -s "${AER_BASE_URL}/ws/user/${AER_USER_ID}/submissions" | sed 's/},{/\n/g' | grep -m 1 -e "\"num\":${PROBLEM_ID}")
        local last_verdict=$(echo "${last_submission}" | grep -o -e '"result":"[A-Z]\+"' | awk -F '"' '{print $4}')
        case "${last_verdict}" in
            AC)
                cout success "Accepted"
                return
                ;;
            IQ)
                cout info "In queue: <${FILENAME}>"
                ;;
            *)
                cout error "${last_verdict}"
                ;;
        esac
        sleep 3
    done
    cout error "Failed to get verdict."
}

function aer_upload_file() {
    local currentPageInput="/problem/send.php?id=${PROBLEM_ID}"
    local sentCodeInput="sentCodeFile"
    local catInput="-1"
    local idInput="${PROBLEM_ID}"
    local languageInput="$(echo "${LANG}" | tr '[:lower:]' '[:upper:]')"
    local solutionFile="${FULLPATH}"
    curl -X POST -v -f -s -L -w '%{url_effective}' --compressed --cookie "${AER_COOKIES_FILE}" --cookie-jar "${AER_COOKIES_FILE}" -H "Content-Type: multipart/form-data" \
        -F currentPage=${currentPageInput} -F cat=${catInput} -F sentCode=${sentCodeInput} -F comment="" -F immediateCode="" \
        -F id=${idInput} -F language=${languageInput} -F "inputFile=@${solutionFile}" ${AER_SUBMIT_URL} &> /dev/null
}

function aer_submit() {
    aer_try_login
    aer_set_user_id
    local -i datetime_before_submission=$(date +%s)
    cout info "Uploading <${FILENAME}> datetime <${datetime_before_submission}>"
    aer_upload_file
    aer_verdict "${datetime_before_submission}"
}
