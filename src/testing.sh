#!/bin/bash

function set_test() {
    is_digit ${NO_TEST}

    # Delete previous tests
    rm -f ${TEST_DIR}/*

    for (( i=0; i < ${NO_TEST}; i+=1 ))
    do
        vim -O2 ${TEST_DIR}/test_input_${i}.txt ${TEST_DIR}/test_output_${i}.txt
    done
}

function testing() {
    NO_TEST=$(( $(ls -l test*txt | wc -l) / 2 ))

    for (( i=0; i < ${NO_TEST}; i+=1 ))
    do
        execute ${TEST_DIR}/test_input_${i}.txt
        diff ${IO_DIR}/output ${TEST_DIR}/test_output_${i}.txt > /dev/null
        if [[ $? != 0 ]]
        then
            printf "Test #${i}\n"

            # Preserve the colorful output from diff command
			diff $MDS_OUTPUT test_output_${i}.txt | xargs -L 1 -I {} echo {} | \
            while read LINE; do \
                GREP_COLORS='ms=1;31'; echo ${LINE} | grep --color=always -e '<.*'; \
                GREP_COLORS='ms=1;34'; echo ${LINE} | grep --color=always - ; \
                GREP_COLORS='ms=1;37'; echo ${LINE} | grep --color=always -e '^[0-9].*' ; \
                GREP_COLORS='ms=1;32'; echo ${LINE} | grep --color=always -e '>.*'; \
			done;

            echo $'\e[1;31mWrong Answer :('$'\e[0m'
            printf "\nDo you want to check the mismatches? (y/n) "
            read -n 1 OPT

            if [[ $OPT == "y" || $OPT == "Y" ]]; then
                vimdiff $MDS_OUTPUT test_output_${i}.txt
            else
                printf "\nOk, don't worry.\n"
            fi
            exit 0
        fi
    done
    echo $'\e[1;32mALL TESTS PASSED!'$'\e[0m'
}
