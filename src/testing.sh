#!/bin/bash

function delete_old_tests() {
    TEST_FILES=($(ls -l --time-style=full-iso ${TEST_DIR} | tail -n +2 | awk '{print $6" "$NF}' | paste -s -d ' '))
    CURRENT_DATE=$(date +%s)
    for (( i=0, j=1; i < ${#TEST_FILES[@]}; i+=2,j+=2 ))
    do
        CREATION_DATE=$(date +%s -d "${TEST_FILES[${i}]}")
        DAYS_DIFF=$(( (${CURRENT_DATE} - ${CREATION_DATE}) / (60 * 60 * 24) ))
        if [[ ${DAYS_DIFF} -ge 14 ]]
        then
            rm -rf ${TEST_DIR}/${TEST_FILES[${j}]} &> /dev/null
        fi
    done
}

function align_tests() {
    TEST_SRC_FOLDER=${1}
    LIST_NO_TESTS=($(ls -l ${TEST_SRC_FOLDER} | grep '.txt' | awk '{print $NF}' | grep -o -e '[0-9]*' | sort | uniq | paste -s -d ' '))

    for (( i=0; i < ${#LIST_NO_TESTS[@]}; i+=1 ))
    do
        cat ${TEST_SRC_FOLDER}/test_input_${LIST_NO_TESTS[${i}]}.txt > ${TEST_SRC_FOLDER}/test_input_${i}.tmp
        cat ${TEST_SRC_FOLDER}/test_output_${LIST_NO_TESTS[${i}]}.txt > ${TEST_SRC_FOLDER}/test_output_${i}.tmp
    done

    rm -f ${TEST_SRC_FOLDER}/*.txt

    for (( i=0; i < ${#LIST_NO_TESTS[@]}; i+=1 ))
    do
        mv ${TEST_SRC_FOLDER}/test_input_${i}.tmp ${TEST_SRC_FOLDER}/test_input_${i}.txt
        mv ${TEST_SRC_FOLDER}/test_output_${i}.tmp ${TEST_SRC_FOLDER}/test_output_${i}.txt
    done
}

function set_test() {
    delete_old_tests
    is_digit ${NO_TEST}

    TEST_SRC_FOLDER_NAME=$(echo ${CWSRC_FILE} | sed 's/\./_/g')
    TEST_SRC_FOLDER=${TEST_DIR}/${TEST_SRC_FOLDER_NAME}

    mkdir -p ${TEST_SRC_FOLDER}

    START_TEST_NUM=0
    CURR_EXISTING_TEST_NUM=$(( $(ls -l ${TEST_SRC_FOLDER} | grep '.txt' | wc -l) / 2 ))
    if [[ ${CURR_EXISTING_TEST_NUM} > 0 ]]
    then
        START_TEST_NUM=$(ls -l ${TEST_SRC_FOLDER} | tail -n +2 | awk '{print $NF}' | grep -o -e '[0-9]*' | sort | uniq | tail -n 1)
        START_TEST_NUM=$(( ${START_TEST_NUM} + 1 ))
    fi

    END_TEST_NUM=$(( ${START_TEST_NUM} + ${NO_TEST} ))
    for (( i=${START_TEST_NUM}; i < ${END_TEST_NUM}; i+=1 ))
    do
        vim -O2 ${TEST_SRC_FOLDER}/test_input_${i}.txt ${TEST_SRC_FOLDER}/test_output_${i}.txt
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
    TEST_SRC_FOLDER_NAME=$(echo ${CWSRC_FILE} | sed 's/\./_/g')
    TEST_SRC_FOLDER=${TEST_DIR}/${TEST_SRC_FOLDER_NAME}
    NO_TEST=$(( $(ls -l ${TEST_DIR}/test*txt | wc -l) / 2 ))

    for (( i=0; i < ${NO_TEST}; i+=1 ))
    do
        cout warning "Test Case #${i}"
        execute ${TEST_SRC_FOLDER}/test_input_${i}.txt
        diff ${IO_DIR}/output ${TEST_SRC_FOLDER}/test_output_${i}.txt > /dev/null
        if [[ $? != 0 ]]
        then
            printf "Test #${i}\n"
            MAX_LINES=300;
            LINES_CONT=1

            # Preserve the colorful output from diff command
            diff $MDS_OUTPUT ${TEST_SRC_FOLDER}/test_output_${i}.txt | xargs -L 1 -I {} echo {} | \
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
                vimdiff $MDS_OUTPUT ${TEST_SRC_FOLDER}/test_output_${i}.txt
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
