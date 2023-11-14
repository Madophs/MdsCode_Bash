#!/bin/bash

source ${SRC_DIR}/args_flags.sh

function parse_args() {
    if [[ $# == 0 ]]
    then
        cout error "No parameters specified"
    fi

    while (( $# ))
    do
        case $1 in
            -h|--help)
                display_help
                exit 0
                ;;
            -f|--file-type)
                param_validation ${1} ${2}
                FILETYPE="${2}"
                CREATION="Y"
                shift
                shift
                ;;
            -n|--filename)
                param_validation ${1} ${2}
                FILENAME=${2}
                shift
                shift
                while [[ -n ${1} && $(is_cmd_option ${1}) == NO ]]
                do
                    FILENAME="${FILENAME} ${1}"
                    shift
                done
                separate_filepath_and_filename FILENAME FILEPATH
                ;;
            -c|--create)
                CREATION="Y"
                shift
                ;;
            -b|--build)
                BUILDING="Y"
                shift
                ;;
            --force-build)
                BUILDING="Y"
                ALWAYS_BUILD="Y"
                shift
                ;;
            -e|--exec)
                EXECUTION="Y"
                shift
                ;;
            --exer)
                EXECUTION="Y"
                REDIRECT_OP=">"
                shift
                ;;
            -i|--io)
                param_validation ${1} ${2}
                IO_TYPE=$(echo ${2} | tr '[:lower:]' '[:upper:]')
                shift
                shift
                ;;
            -t|--test)
                TESTING="Y"
                EXECUTION="Y"
                if [[ -n ${2} && $(is_cmd_option ${2}) == "NO" ]]
                then
                    CWSRC_FILE=${2}
                    shift
                else
                    CWSRC_FILE=$(get_last_source_file)
                fi
                shift
                ;;
            -a|--add)
                param_validation ${1} ${2}
                NO_TEST=${2}
                CREATE_TESTS="Y"
                if [[ -n ${3} && $(is_cmd_option ${3}) == "NO" ]]
                then
                    CWSRC_FILE=${3}
                    shift
                else
                    CWSRC_FILE=$(get_last_source_file)
                fi
                shift
                shift
                ;;
            --set-test)
                param_validation ${1} ${2}
                SET_TEST=${2}
                shift
                shift
                ;;
            -p|--template)
                param_validation ${1} ${2}
                TEMPLATE=${2}
                shift
                shift
                ;;
            -g|--gui)
                GUI="Y"
                shift
                ;;
            -s|--submit)
                SUBMIT="Y"
                if [[ -n ${2} ]]
                then
                    SOURCE_FILE=${2}
                    shift
                fi
                shift
                ;;
            -x|--debug)
                DEBUG="Y"
                shift
                ;;
            --flags)
                OPEN_FLAGS="Y"
                shift
                ;;
            -*|--*=)
                cout error "Unknown option \"${1}\""
                shift
                ;;
            *)
                cout error "Unknown argument ${1}"
                shift
                ;;
        esac
    done
}
