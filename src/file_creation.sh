#!/bin/bash

function apply_naming_convention() {
    missing_argument_validation 2 ${1} ${2}
    declare -n filename=${1}
    local file_extension=${2}

    if [[ ${IGNORE_RENAMING} == Y ]]
    then
        filename="${filename}.${file_extension}"
        return 0
    fi

    if [[ ${CONFIGS_MAP['PROBLEM_ID_AT_END']} == YES  && -z "${PROBLEM_ID}" ]]
    then
        PROBLEM_ID=$(echo ${filename} | grep -o -e '^[0-9]\+')
        if [[ -n ${PROBLEM_ID} ]]
        then
            filename=$(echo ${filename} | sed "s/^${PROBLEM_ID}//g")
        fi
    fi

    filename=$(echo ${filename} | sed "s/\.${file_extension}//g")

    # trim leading/trailing whitespaces
    filename=$(echo ${filename} | sed 's/^ *//g;s/ *$//g')

    # Remove weird characters
    filename=$(sed 's/[^a-zA-Z 0-9\-_]//g' <(echo ${filename}))

    # Replacing non-english characters
    filename=$(sed 's/á/a/g;s/é/e/g;s/í/i/g;s/ó/o/g;s/ú/u/g;s/ü/u/g;s/ñ/n/g' <(echo $filename))
    filename=$(sed 's/Á/A/g;s/É/E/g;s/Í/I/g;s/Ó/O/g;s/Ú/U/g;s/Ü/U/g;s/Ñ/N/g' <(echo $filename))

    case ${CONFIGS_MAP['CASETYPE']} in
        UCWORDS)
            filename="$(echo ${filename} | sed -e 's/\b\(.\)/\u\1/g')"
        ;;
        UPPERCASE)
            filename="$(echo ${filename} | tr '[:lower:]' '[:upper:]')"
        ;;
        LOWERCASE)
            filename="$(echo ${filename} | tr '[:upper:]' '[:lower:]')"
        ;;
        *)
            cout warning "Ignoring unknown casetype ${CONFIGS_MAP['CASETYPE']}"
        ;;
    esac

    if [[ -n "${PROBLEM_ID}" ]]
    then
        filename="${filename} ${PROBLEM_ID}"
    fi

    filename=$(sed "s/ /${CONFIGS_MAP['WHITESPACE_REPLACE']}/g;s/-/${CONFIGS_MAP['WHITESPACE_REPLACE']}/g" <(echo ${filename}))
    filename="${filename}.${file_extension}"
}

function set_default_template() {
    local filetype=${1}
    if [[ -f ${TEMPLATES_DIR}/default.${filetype} ]]
    then
        TEMPLATE=default.${filetype}
    else
        TEMPLATE=none
    fi
}

function load_template() {
    declare -n template_content_ref=${1}
    local file_type=${2}
    if [[ -z ${TEMPLATE} ]]
    then
        if [[ -f "${TEMPLATES_DIR}/default.${file_type}" ]]
        then
            template_content_ref=$(cat "${TEMPLATES_DIR}/default.${file_type}")
        else
            cout warning "Default ${file_type} template not found."
        fi
    else
        if [[ -f ${TEMPLATES_DIR}/${TEMPLATE} ]]
        then
            template_content_ref=$(cat "${TEMPLATES_DIR}/${TEMPLATE}")
        elif [[ ${TEMPLATE} != none ]]
        then
            cout warning "Template ${TEMPLATE} not found."
        fi
    fi
}

function create_file() {
    if [[ -n "${PROBLEM_URL}" ]]
    then
        set_problem_data_by_url
    fi

    if [[ -z ${FILETYPE} ]]
    then
        FILETYPE=$(get_file_extension "${FILENAME}")
        if [[ -z ${FILETYPE} ]]
        then
            cout warning "Filetype not specified using default: ${CONFIGS_MAP['DEFAULT_FILETYPE']}"
            FILETYPE=${CONFIGS_MAP['DEFAULT_FILETYPE']}
        fi
    fi

    if [[ -n ${FILENAME} ]]
    then
        apply_naming_convention FILENAME ${FILETYPE}
        load_template template_content ${FILETYPE}

        local file_fullpath="${FILEPATH}${FILENAME}"
        if [[ -f ${file_fullpath} ]]
        then
            cout warning "File ${FILENAME} already exists."
            cout info "Replace? (Y/N)"
            local input
            read input
            if [[ ${input} == y  || ${input} == Y ]]
            then
                cout warning "Replacing file."
                echo -e "${template_content}" > "${file_fullpath}"
                cout success "File \"${FILENAME}\" replaced successfully."
                save_build_data
            else
                cout info "Wise choice, bye..."
            fi
        else
            echo -e "${template_content}" > "${file_fullpath}"
            save_build_data
            cout success "File \"${FILENAME}\" created successfully."
        fi
    else
        cout error "Filename not specified."
    fi
}
