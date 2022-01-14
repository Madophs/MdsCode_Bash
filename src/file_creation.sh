#!/bin/bash

function apply_naming_convention() {
    # Remove weird characters
    FILENAME=$(sed 's/[^a-zA-Z 0-9]//g' <(echo $FILENAME))

    # Replacing non-english characters
    FILENAME=$(sed 's/á/a/g;s/é/e/g;s/í/i/g;s/ó/o/g;s/ú/u/g;s/ü/u/g;s/ñ/n/g' <(echo $FILENAME))
    FILENAME=$(sed 's/Á/A/g;s/É/E/g;s/Í/I/g;s/Ó/O/g;s/Ú/U/g;s/Ü/U/g;s/Ñ/N/g' <(echo $FILENAME))

    if [[ $CASETYPE == "UCWORDS" ]]
    then
        FILENAME=$(echo $FILENAME | sed -e 's/\b\(.\)/\u\1/g')
    elif [[ $CASETYPE == "UPPERCASE" ]]
    then
        FILENAME=$(echo $FILENAME | tr '[:lower:]' '[:upper:]')
    elif [[ $CASETYPE == "LOWERCASE" ]]
    then
        FILENAME=$(echo $FILENAME | tr '[:upper:]' '[:lower:]')
    else
        echo "[ERROR] Unknown casetype [${CASETYPE}]"
    fi

    FILENAME=$(sed "s/ /${WHITESPACE_REPLACE}/g" <(echo $FILENAME))
}

function create_file() {
    if [[ -n $FILE_TYPE ]]
    then
        # Create the file in a tmp location
        TEMP_FILE="main_"$(date +'%s').$FILE_TYPE
        touch ${TEMP_DIR}/${TEMP_FILE}

        if [[ -z $TEMPLATE ]]
        then
            if [[ -f ${TEMPLATES_DIR}/default.${FILE_TYPE} ]]
            then
                cat ${TEMPLATES_DIR}/default.${FILE_TYPE} > ${TEMP_DIR}/${TEMP_FILE}
            else
                cout warning "[WARNING] Default ${FILE_TYPE} template not found."
                cout info "[INFO] Creating a simple empty file."
            fi
        else
            if [[ -f ${TEMPLATES_DIR}/${TEMPLATE} ]]
            then
                cat ${TEMPLATES_DIR}/${TEMPLATE} > ${TEMP_DIR}/${TEMP_FILE}
            else
                cout warning "[WARNING] Default ${FILE_TYPE} template not found, creating an empty file"
            fi
        fi

        if [[ -n $FILENAME ]]
        then
            apply_naming_convention

            # Check if file already exists
            ls -f ${FILENAME}.${FILE_TYPE} &> /dev/null
            if [[ $? == 0 ]]
            then
                echo "[INFO] File ${FILENAME}.${FILE_TYPE} already exists."
                echo "Replace? (Y/N)"
                read DECISION
                if [[ $DECISION == "y"  || $DECISION == "Y" ]]
                then
                    echo "[WARNING] Replacing file."
                    cat ${TEMP_DIR}/${TEMP_FILE} > ${FILENAME}.${FILE_TYPE}
                    echo "[SUCCESS] File \"${FILENAME}.${FILE_TYPE}\" created successfully."
                else
                    echo "[INFO] Wise choice, bye..."
                    exit 0
                fi
            else
                cat ${TEMP_DIR}/${TEMP_FILE} > ${FILENAME}.${FILE_TYPE}
                echo "[SUCCESS] File \"${FILENAME}.${FILE_TYPE}\" created successfully."
            fi
        else
            echo "[INFO] Filename not specified, file generated with a random name \"$TEMP_FILE\""
            cp ${TEMP_DIR}/${TEMP_FILE} .
        fi
    fi
}
