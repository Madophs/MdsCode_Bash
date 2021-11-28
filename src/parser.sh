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
            USE_TEMPLATE="Y"
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

