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

function set_nth_test_as_input() {
    TARGET_TEST=${TEST_DIR}/test_input_${SET_TEST}.txt
    echo ${TARGET_TEST}
    if [[ -f ${TARGET_TEST} ]]
    then
        cat ${TARGET_TEST} > ${MDS_INPUT}
    else
        cout danger "[ERROR] Test not found."
    fi
}

function testing() {
    NO_TEST=$(( $(ls -l ${TEST_DIR}/test*txt | wc -l) / 2 ))

    for (( i=0; i < ${NO_TEST}; i+=1 ))
    do
        execute ${TEST_DIR}/test_input_${i}.txt
        diff ${IO_DIR}/output ${TEST_DIR}/test_output_${i}.txt > /dev/null
        if [[ $? != 0 ]]
        then
            printf "Test #${i}\n"
            MAX_LINES=300;
            LINES_CONT=1

            # Preserve the colorful output from diff command
            diff $MDS_OUTPUT ${TEST_DIR}/test_output_${i}.txt | xargs -L 1 -I {} echo {} | \
            while read LINE; do \
                GREP_COLORS='ms=1;31'; echo ${LINE} | grep --color=always -e '<.*'; \
                GREP_COLORS='ms=1;34'; echo ${LINE} | grep --color=always - ; \
                GREP_COLORS='ms=1;37'; echo ${LINE} | grep --color=always -e '^[0-9].*' ; \
                GREP_COLORS='ms=1;32'; echo ${LINE} | grep --color=always -e '>.*'; \
                LINES_CONT=$(( LINES_CONT + 1 )); \
                if [[ ${LINES_CONT} -ge ${MAX_LINES} ]]; \
                then \
                    break;\
                fi; \
            done;

            cout danger "Wrong Answer :("
            printf "\nDo you want to check the mismatches? (y/n) "
            read -n 1 OPT

            if [[ $OPT == "y" || $OPT == "Y" ]]; then
                vimdiff $MDS_OUTPUT ${TEST_DIR}/test_output_${i}.txt
            else
                echo ""
                cout green "Ok, don't worry."
                echo ""
            fi
            exit 0
        fi
    done
    cout success "ALL TESTS PASSED!"
}
