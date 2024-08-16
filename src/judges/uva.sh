#!/bin/bash

UVA_BASE_URL="https://onlinejudge.org"
UVA_INDEX_URL=${UVA_BASE_URL}/index.php
UVA_LOGIN_URL="${UVA_INDEX_URL}?option=com_comprofiler&task=login"
UVA_COOKIES_FILE=${BUILD_DIR}/uva_cookies
UVA_SUBMIT_URL="${UVA_INDEX_URL}?option=com_onlinejudge&Itemid=25&page=save_submission"
UVA_SUBMISSIONS_URL="https://onlinejudge.org/index.php?option=com_onlinejudge&Itemid=9"

function uva_get_hidden_params() {
    curl -f -L -s  ${UVA_BASE_URL} | grep -B8 'id=\"mod_login_remember\"' | awk '{print $3  $4}' | grep -v 'remember' | awk -F '[=\"]' '{print $3"="$6}' | tr '\n' '\&' | sed 's/\&$/\&remember=yes/g'
}

function uva_already_logged() {
    curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_INDEX_URL} | grep -i -E 'register|unavailable' &> /dev/null
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
            read -n opt
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

function uva_verdict() {
    cout info "Waiting for verdict..."
    MAX_TRIES=20
    local error_type=1
    local problem_id=${1}
    local datetime_before_submission=${2}
    local latest_entry=$(curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_SUBMISSIONS_URL} | grep '<tr class="sectiontableentry' -A 8 -m 1)
    local latest_problem_id=$(echo ${latest_entry} | grep -o -e ">${problem_id}<" | grep -o -e '[0-9]\+')
    for i in $(seq ${MAX_TRIES})
    do
        error_type=1
        if [[ ${latest_problem_id} != ${problem_id} ]]
        then
            local latest_problem_id=$(echo ${latest_entry} | grep -o -e ">${problem_id}<" | grep -o -e '[0-9]\+')
            error_type=2
            sleep 2
            continue
        fi

        local latest_entry=$(curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_SUBMISSIONS_URL} | grep '<tr class="sectiontableentry' -A 8 -m 1)
        local datetime_submission=$(date +%s -d "$(echo ${latest_entry} | grep -o -e '[0-9]\+-[0-9]\+-[0-9]\+ [0-9]\+:[0-9]\+:[0-9]\+')")
        if [[ ${datetime_submission} < ${datetime_before_submission} ]]
        then
            error_type=3
            sleep 2
            continue
        fi

        declare -g verdict=$(echo ${latest_entry} | grep -m 1 -o -e "<td>[A-Z a-z']\+</td>" | awk -F '[<>]' '{print $3}')
        if [[ -n $(echo ${verdict} | grep -o -i 'queue') ]]
        then
            sleep 2
            continue
        fi
        break
    done

    if [[ ${MAX_TRIES} == ${i} ]]
    then
        case ${error_type} in
            1)
                cout error "Reached max number of tries"
            ;;
            2)
                cout error "Couldn't find problem_id ${problem_id} in submission dashboard"
            ;;
            3)
                cout error "Failed to find lastest submission"
            ;;
        esac
    elif [[ ${verdict} == Accepted ]]
    then
        cout success ${verdict}
    else
        cout error ${verdict}
    fi
}

function set_upload_date()
{
    declare -n current_date_ref=${1}
    declare -n formatted_date_ref=${2}
    export TZ="${CONFIGS_MAP['UVA_TIMEZONE']}"
    current_date_ref=$(date +%s)
    formatted_date_ref=$(date '+%F %T' -d @"${current_date_ref}")
}

function uva_submit() {
    uva_try_login

    if [[ -z ${ORIGINAL_SOURCE} ]]
    then
        source ${BUILD_INFO}
    fi

    local problem_id=$(uva_get_problem_id "${ORIGINAL_SOURCE}")
    local language_id=$(uva_get_lang_id "${ORIGINAL_SOURCE}")
    local filename=$(get_last_source_file)

    if [[ -z ${problem_id} || -z ${language_id} ]]
    then
        cout error "Unable to upload file: ${ORIGINAL_SOURCE}, problem_id: ${problem_id}"
    fi

    set_upload_date datetime_before_submission date_formatted
    cout info "Uploading... ${filename}"
    cout info "Submission date: ${date_formatted}"

    # file upload
    curl -X POST -f -L -s -w '%{url_effective}' --compressed --cookie ${UVA_COOKIES_FILE} --cookie-jar ${UVA_COOKIES_FILE} -H "Content-Type: multipart/form-data" \
        -F localid=${problem_id}  -F language=${language_id} -F "codeupl=@${ORIGINAL_SOURCE}" ${UVA_SUBMIT_URL} &> /dev/null

    if [[ $(exit_is_zero $?) == YES ]]
    then
        cout info "File uploaded!!!"
        uva_verdict "${problem_id}" "${datetime_before_submission}"
    else
        cout error "Something went wrong :("
    fi
}
