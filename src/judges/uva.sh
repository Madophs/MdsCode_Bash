#!/bin/bash

UVA_BASE_URL="https://onlinejudge.org"
UVA_INDEX_URL=${UVA_BASE_URL}/index.php
UVA_LOGIN_URL="${UVA_INDEX_URL}?option=com_comprofiler&task=login"
UVA_COOKIES_FILE=${COOKIES_DIR}/uva_cookies
UVA_SUBMIT_URL="${UVA_INDEX_URL}?option=com_onlinejudge&Itemid=25&page=save_submission"
UVA_SUBMISSIONS_URL="https://onlinejudge.org/index.php?option=com_onlinejudge&Itemid=9"

function uva_parse_problem_data() {
    missing_argument_validation 2 ${1} ${2}
    declare -n filename=${1}
    declare -n problem_id=${2}
    local is_uva_pdf_url=$(echo "${PROBLEM_URL}" | grep -e '^https:.\+\.pdf$')
    if [[ -n "${is_uva_pdf_url}" ]]
    then
        problem_id=$(echo "${PROBLEM_URL}" | grep -o -e '[0-9]\+.pdf$' | grep -o -e '^[0-9]\+')
        filename=$(curl -L -s "https://vjudge.net/problem/UVA-${problem_id}/origin" | grep -e '<h3>[0-9]\+ - .\+<\/h3>' | awk -F '[<>]' '{print $3}' | sed 's/^[0-9]\+ - //g')
    else
        local raw_name=$(curl -L -s "${PROBLEM_URL}" | grep -e '<h3>[0-9]\+ - .\+<\/h3>' | awk -F '[<>]' '{print $3}')
        problem_id=$(echo "${raw_name}" | grep -o -e '^[0-9]\+')
        filename=$(echo "${raw_name}" | sed 's/^[0-9]\+ - //g')
    fi

    if [[ -z ${filename} || -z ${problem_id} ]]
    then
        cout error "UVA online judge: failed to retrieve problem data."
    fi
}

function uva_parse_sample_tests() {
    declare -n sample_input_ref=${1}
    declare -n sample_output_ref=${2}
    local file_content=$(cat "${TEMP_DIR}/${PROBLEM_ID}.txt")

    local new_page_index=$(printf "%s\n" "${file_content}" | grep -n -e 'Universidad de Valladolid OJ' | grep -o -e '^[0-9]\+')
    if [[ -n "${new_page_index}" ]]
    then
        local file_content=$(echo "${file_content}" | sed "${new_page_index},$(( new_page_index + 2 ))d")
    fi

    local -a num_lines=( $(printf "%s\n" "${file_content}" | grep -n -e 'Sample \(Input\|Output\)' | grep -o -e '^[0-9]\+') )
    local -i lines_count=$(printf "%s\n" "${file_content}" | wc -l | grep -o -e '^[-1-9]\+')
    local -i gap_btw_in_out=$(( num_lines[1] - num_lines[0] - 2 ))

    sample_input_ref=$(printf "%s\n" "${file_content}" | sed -n "$(( ${num_lines[0]} + 1 )),$(( gap_btw_in_out + ${num_lines[0]} )){p}") # sed -n {line_start},{line_end}{p}
    sample_output_ref=$(printf "%s\n" "${file_content}" | sed -n "$(( ${num_lines[1]} + 1 )),${lines_count}{p}") # sed -n {line_start},{line_end}{p}
}

function uva_download_problem_pdf() {
    if [[ -f "${TEMP_DIR}/${PROBLEM_ID}.pdf" ]]
    then
        return
    fi

    local is_uva_pdf_url=$(echo "${PROBLEM_URL}" | grep -e '^https:.\+\.pdf$')
    if [[ -n "${is_uva_pdf_url}" ]]
    then
        local pdf_link="${PROBLEM_URL}"
    else
        local pdf_href=$(curl -L -s "${PROBLEM_URL}" | grep -o -e '\"external/.\+pdf"' | sed 's|"||g')
        local pdf_link="${UVA_BASE_URL}/${pdf_href}"
    fi

    wget -q "${pdf_link}" -P "${TEMP_DIR}"
}

function uva_set_sample_test() {
    uva_download_problem_pdf
    pdftotext -layout -nopgbrk "${TEMP_DIR}/${PROBLEM_ID}.pdf" "${TEMP_DIR}/${PROBLEM_ID}.txt"

    local test_src_folder=${TEST_DIR}/${FULLNAME}
    mkdir -p "${test_src_folder}"

    uva_parse_sample_tests sample_input sample_output
    echo -e "${sample_input}" > "${test_src_folder}/test_input_0.txt"
    echo -e "${sample_output}" > "${test_src_folder}/test_output_0.txt"

    SET_TEST_INDEX=0
}

function uva_get_hidden_params() {
    curl -f -L -s  ${UVA_BASE_URL} | grep -B8 'id=\"mod_login_remember\"' | awk '{print $3  $4}' | grep -v 'remember' | awk -F '[=\"]' '{print $3"="$6}' | tr '\n' '\&' | sed 's/\&$/\&remember=yes/g'
}

function is_uva_available() {
    (curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_INDEX_URL} | grep -i -e 'My uHunt with Virtual Contest Service' &> /dev/null) || cout error "UVA judge online is not available"
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
            latest_entry=$(curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_SUBMISSIONS_URL} | grep '<tr class="sectiontableentry' -A 8 -m 1)
            latest_problem_id=$(echo ${latest_entry} | grep -o -e ">${problem_id}<" | grep -o -e '[0-9]\+')
            error_type=2
            sleep 2
            continue
        fi

        latest_entry=$(curl -X GET --cookie ${UVA_COOKIES_FILE} -f -s -L --compressed ${UVA_SUBMISSIONS_URL} | grep '<tr class="sectiontableentry' -A 8 -m 1)
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
                cout error "Timeout"
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

function set_upload_date() {
    declare -n current_date_ref=${1}
    declare -n formatted_date_ref=${2}
    export TZ="${CONFIGS_MAP['UVA_TIMEZONE']}"
    current_date_ref=$(date +%s)
    formatted_date_ref=$(date '+%F %T' -d @"${current_date_ref}")
}

function uva_submit() {
    is_uva_available
    uva_try_login

    local filename=${FILENAME}
    local problem_id=${PROBLEM_ID}
    local language_id=$(uva_get_lang_id "${filename}")

    if [[ -z ${problem_id} || -z ${language_id} ]]
    then
        cout error "Unable to upload file: ${FULLPATH}, problem_id: ${problem_id}"
    fi

    set_upload_date datetime_before_submission date_formatted
    cout info "Uploading... ${filename}"
    cout info "Submission date: <<${date_formatted}>>, epoch time: <<${datetime_before_submission}>>"

    sleep 3
    # file upload
    curl -X POST -f -L -s -w '%{url_effective}' --compressed --cookie ${UVA_COOKIES_FILE} --cookie-jar ${UVA_COOKIES_FILE} -H "Content-Type: multipart/form-data" \
        -F localid=${problem_id}  -F language=${language_id} -F "codeupl=@${FULLPATH}" ${UVA_SUBMIT_URL} &> /dev/null

    if [[ $(exit_is_zero $?) == YES ]]
    then
        cout info "File uploaded!!!"
        uva_verdict "${problem_id}" "${datetime_before_submission}"
    else
        cout error "Something went wrong :("
    fi
}
