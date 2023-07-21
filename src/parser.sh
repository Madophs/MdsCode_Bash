#!/bin/bash

source ${SRC_DIR}/args_flags.sh

if [[ $# == 0 ]]
then
    echo "[INFO] No parameters specified"
    exit 0
fi

while (( $# ))
do
    case $1 in
        -h|--help)
            echo "[INFO] Display help"
            display_help
            exit 0
            ;;
        -f|--file-type)
            missing_argument_validation ${1} ${2}
            FILE_TYPE="${2}"
            shift
            shift
            ;;
        -n|--filename)
            missing_argument_validation ${1} ${2}
            FILENAME="${2}"
            shift
            shift

            while [[ -n ${1} && -z $(echo ${1} | grep '-' ) ]]
            do
                FILENAME="${FILENAME} ${1}"
                shift
            done
            CREATION="Y"
            ;;
        -b|--build)
            missing_argument_validation ${1} ${2}
            FILENAME="${2}"
            BUILDING="Y"
            shift
            shift
            ;;
        -e|--exec)
            EXECUTION="Y"
            shift
            ;;
        -i|--io)
            missing_argument_validation ${1} ${2}
            IO_TYPE=$(echo ${2} | tr '[:lower:]' '[:upper:]')
            shift
            shift
            ;;
        -t|--test)
            if [[ ! -z ${2} ]]; then
                NO_TEST=${2}
                CREATE_TESTS="Y"
                shift
            else
                TESTING="Y"
                EXECUTION="Y"
            fi
            shift
            ;;
        -p|--template)
            missing_argument_validation ${1} ${2}
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
        --flags)
            OPEN_FLAGS="Y"
            shift
            ;;
        -*|--*=)
            echo "[ERROR] Unknown argument \"${1}\""
            exit 1
            shift
            ;;
        *)
            echo "[INFO] ${1}"
            shift
            ;;
    esac
done

