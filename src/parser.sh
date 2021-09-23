#!/bin/bash

source ${SRC_DIR}/args_flags.sh

function missing_argument_validation() {
    ARG=${1}
    if [[ -z ${2} ]]
    then
        echo "ERROR: missing argument for [${ARG}]"
        exit 1
    fi
}

while (( $# ))
do
    case $1 in
        -h|--help)
            echo "[INFO] Display help"
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
        -t|--template)
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

