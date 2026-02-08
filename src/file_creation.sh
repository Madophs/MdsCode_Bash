#!/bin/bash

function apply_naming_convention() {
    missing_argument_validation 2 ${1} ${2}
    local -n filename_ref=${1}
    local file_extension=${2}

    if [[ ${IGNORE_RENAMING} == Y ]]
    then
        [[ -z "${filename_ref##*.}" ]] && filename_ref="${filename_ref}.${file_extension}"
        return 0
    fi

    if [[ ${CONFIGS_MAP['PROBLEM_ID_AT_END']} == YES  && -z "${PROBLEM_ID}" ]]
    then
        PROBLEM_ID=$(echo ${filename_ref} | grep -o -e '^[0-9]\+')
        if [[ -n ${PROBLEM_ID} ]]
        then
            filename_ref=$(echo ${filename_ref} | sed "s/^${PROBLEM_ID}//g")
        fi
    fi

    # Remove extension, this last one should be pass as second parameter
    filename_ref=$(echo ${filename_ref} | sed "s/\..*//g")

    # Trim leading/trailing whitespaces
    filename_ref=$(echo ${filename_ref} | sed 's/^ *//g;s/ *$//g')

    # Replace undercores with spaces
    filename_ref=$(echo ${filename_ref} | sed 's/_/ /g')

    # Replacing non-english characters
    filename_ref=$(sed 's/á/a/g;s/é/e/g;s/í/i/g;s/ó/o/g;s/ú/u/g;s/ü/u/g;s/ñ/n/g' <(echo "${filename_ref}"))
    filename_ref=$(sed 's/Á/A/g;s/É/E/g;s/Í/I/g;s/Ó/O/g;s/Ú/U/g;s/Ü/U/g;s/Ñ/N/g' <(echo "${filename_ref}"))

    # Remove weird characters
    filename_ref=$(sed 's/[^a-zA-Z0-9 _-]//g' <(echo "${filename_ref}"))

    case ${CONFIGS_MAP['CASETYPE']} in
        UCWORDS)
            filename_ref="$(echo ${filename_ref} | sed -e 's/\b\(.\)/\u\1/g')"
        ;;
        UPPERCASE)
            filename_ref="$(echo ${filename_ref} | tr '[:lower:]' '[:upper:]')"
        ;;
        LOWERCASE)
            filename_ref="$(echo ${filename_ref} | tr '[:upper:]' '[:lower:]')"
        ;;
        *)
            cout warning "Ignoring unknown casetype ${CONFIGS_MAP['CASETYPE']}"
        ;;
    esac

    if [[ -n "${PROBLEM_ID}" ]]
    then
        filename_ref="${filename_ref} ${PROBLEM_ID}"
    fi

    filename_ref=$(sed "s/ /${CONFIGS_MAP['WHITESPACE_REPLACE']}/g;s/-/${CONFIGS_MAP['WHITESPACE_REPLACE']}/g" <(echo ${filename_ref}))
    filename_ref="${filename_ref}.${file_extension}"
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

        local file_fullpath="${FILEPATH}/${FILENAME}"
        if [[ -f ${file_fullpath} ]]
        then
            cout warning "File ${FILENAME} already exists.\nReplace (Y/N)"
            read input
            if [[ ${input} =~ [yY] ]]
            then
                cout warning "Replacing file."
                printf "%s\n" "${template_content}" > "${file_fullpath}"
                cout success "File \"${FILENAME}\" replaced successfully."
                save_build_data
            else
                [[ ! -d "${BUILD_DIR}/${FILENAME}" ]] && save_build_data && cout info "Generating build data"
                cout info "Wise choice, bye..."
            fi
        else
            printf "%s\n" "${template_content}" > "${file_fullpath}"
            save_build_data
            cout success "File \"${FILENAME}\" created successfully."
        fi
    else
        cout error "Filename not specified."
    fi
}
