#!/bin/bash

function apply_naming_convention() {
    missing_argument_validation 2 ${1} ${2}
    declare -n filename=${1}
    local file_extension=${2}

    filename=$(echo ${filename} | sed "s/\.${file_extension}//g")

    # Remove weird characters
    filename=$(sed 's/[^a-zA-Z 0-9\-_]//g' <(echo ${filename}))

    # Replacing non-english characters
    filename=$(sed 's/á/a/g;s/é/e/g;s/í/i/g;s/ó/o/g;s/ú/u/g;s/ü/u/g;s/ñ/n/g' <(echo $filename))
    filename=$(sed 's/Á/A/g;s/É/E/g;s/Í/I/g;s/Ó/O/g;s/Ú/U/g;s/Ü/U/g;s/Ñ/N/g' <(echo $filename))

    if [[ ${CONFIGS_MAP['CASETYPE']} == UCWORDS ]]
    then
        filename=$(echo ${filename} | sed -e 's/\b\(.\)/\u\1/g')
    elif [[ ${CONFIGS_MAP['CASETYPE']} == UPPERCASE ]]
    then
        filename=$(echo ${filename} | tr '[:lower:]' '[:upper:]')
    elif [[ ${CONFIGS_MAP['CASETYPE']} == LOWERCASE ]]
    then
        filename=$(echo ${filename} | tr '[:upper:]' '[:lower:]')
    else
        cout error "Unknown casetype [${CONFIGS_MAP['CASETYPE']}]"
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
    local file=${1}
    local file_type=${2}
    if [[ -z ${TEMPLATE} ]]
    then
        if [[ -f "${TEMPLATES_DIR}/default.${file_type}" ]]
        then
            cat ${TEMPLATES_DIR}/default.${file_type} > ${file}
        else
            cout warning "Default ${file_type} template not found."
            cout info "Creating a simple empty file."
        fi
    else
        if [[ -f ${TEMPLATES_DIR}/${TEMPLATE} ]]
        then
            cat ${TEMPLATES_DIR}/${TEMPLATE} > ${file}
        elif [[ ${TEMPLATE} != none ]]
        then
            cout warning "Template ${TEMPLATE} not found, creating an empty file."
        fi
    fi
}

function create_file() {
    if [[ -z ${FILETYPE} ]]
    then
        FILETYPE=$(get_file_extension "${FILENAME}")
        if [[ -z ${FILETYPE} ]]
        then
            cout warning "Filetype not specified using default: ${CONFIGS_MAP['DEFAULT_FILETYPE']}"
            FILETYPE=${CONFIGS_MAP['DEFAULT_FILETYPE']}
        fi
    fi

    # Create the file in a tmp location
    local tmp_filename="main_$(date +'%s').${FILETYPE}"
    local tmp_file="${TEMP_DIR}/${tmp_filename}"
    touch ${tmp_file}

    if [[ -n ${FILENAME} ]]
    then
        apply_naming_convention FILENAME ${FILETYPE}
        load_template ${tmp_file} ${FILETYPE}

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
                cat ${tmp_file} > ${file_fullpath}
                cout success "File \"${FILENAME}\" replaced successfully."
                open_with_editor "${file_fullpath}"
            else
                cout info "Wise choice, bye..."
            fi
        else
            cat ${tmp_file} > ${file_fullpath}
            cout success "File \"${FILENAME}\" created successfully."
            open_with_editor "${file_fullpath}"
        fi
    else
        load_template ${tmp_file} ${FILETYPE}
        cout warning "Filename not specified, file generated with a random name \"${tmp_filename}\""
        cp ${tmp_file} .
        open_with_editor "${tmp_filename}"
    fi
}
