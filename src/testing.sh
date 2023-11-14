#!/bin/bash

function delete_old_tests() {
    local test_files=($(ls -l --time-style=full-iso ${TEST_DIR} | tail -n +2 | awk '{print $6" "$NF}' | paste -s -d ' '))
    local current_date=$(date +%s)
    for (( i=0, j=1; i < ${#test_files[@]}; i+=2,j+=2 ))
    do
        local creation_date=$(date +%s -d "${test_files[${i}]}")
        local days_diff=$(( (${current_date} - ${creation_date}) / (60 * 60 * 24) ))
        if [[ ${days_diff} -ge 14 ]]
        then
            rm -rf ${TEST_DIR}/${test_files[${j}]} &> /dev/null
        fi
    done
}

function align_tests() {
    local test_src_folder=${1}
    local list_no_test=($(ls -l ${test_src_folder} | grep '.txt' | awk '{print $NF}' | grep -o -e '[0-9]*' | sort | uniq | paste -s -d ' '))

    for (( i=0; i < ${#list_no_test[@]}; i+=1 ))
    do
        cat ${test_src_folder}/test_input_${list_no_test[${i}]}.txt > ${test_src_folder}/test_input_${i}.tmp
        cat ${test_src_folder}/test_output_${list_no_test[${i}]}.txt > ${test_src_folder}/test_output_${i}.tmp
    done

    rm -f ${test_src_folder}/*.txt

    for (( i=0; i < ${#list_no_test[@]}; i+=1 ))
    do
        mv ${test_src_folder}/test_input_${i}.tmp ${test_src_folder}/test_input_${i}.txt
        mv ${test_src_folder}/test_output_${i}.tmp ${test_src_folder}/test_output_${i}.txt
    done
}

function set_test() {
    delete_old_tests
    is_digit ${NO_TEST}

    local test_src_folder_name=$(echo ${CWSRC_FILE} | sed 's/\./_/g')
    local test_src_folder=${TEST_DIR}/${test_src_folder_name}

    mkdir -p ${test_src_folder}

    local start_test_num=0
    local curr_existing_test_num=$(( $(ls -l ${test_src_folder} | grep '.txt' | wc -l) / 2 ))
    if [[ ${curr_existing_test_num} > 0 ]]
    then
        start_test_num=$(ls -l ${test_src_folder} | tail -n +2 | awk '{print $NF}' | grep -o -e '[0-9]*' | sort | uniq | tail -n 1)
        start_test_num=$(( ${start_test_num} + 1 ))
    fi

    local end_test_num=$(( ${start_test_num} + ${NO_TEST} ))
    for (( i=${start_test_num}; i < ${end_test_num}; i+=1 ))
    do
        vim -O2 ${test_src_folder}/test_input_${i}.txt ${test_src_folder}/test_output_${i}.txt
    done
}

function set_nth_test_as_input() {
    local test_src_folder_name=$(echo ${CWSRC_FILE} | sed 's/\./_/g')
    local test_src_folder=${TEST_DIR}/${test_src_folder_name}
    local target_test=${test_src_folder}/test_input_${SET_TEST}.txt
    if [[ -f ${target_test} ]]
    then
        cat ${target_test} > ${MDS_INPUT}
    else
        cout error "Test not found."
    fi
}

function testing() {
    local test_src_folder_name=$(echo ${CWSRC_FILE} | sed 's/\./_/g')
    local test_src_folder=${TEST_DIR}/${test_src_folder_name}
    local no_test=$(( $(ls -l ${test_src_folder}/test*txt | wc -l) / 2 ))

    for (( i=0; i < ${no_test}; i+=1 ))
    do
        cout info "Test Case #${i}"
        execute ${test_src_folder}/test_input_${i}.txt
        diff ${MDS_OUTPUT} ${test_src_folder}/test_output_${i}.txt > /dev/null
        if [[ $? != 0 ]]
        then
            printf "Test #${i}\n"
            local max_lines=300;
            local lines_cont=1

            # Preserve the colorful output from diff command
            diff ${MDS_OUTPUT} ${test_src_folder}/test_output_${i}.txt | xargs -L 1 -I {} echo {} | \
            while read line; do \
                GREP_COLORS='ms=1;31'; echo ${line} | grep --color=always -e '<.*'; \
                GREP_COLORS='ms=1;34'; echo ${line} | grep --color=always - ; \
                GREP_COLORS='ms=1;37'; echo ${line} | grep --color=always -e '^[0-9].*' ; \
                GREP_COLORS='ms=1;32'; echo ${line} | grep --color=always -e '>.*'; \
                lines_cont=$(( lines_cont + 1 )); \
                if [[ ${lines_cont} -ge ${max_lines} ]]; \
                then \
                    break;\
                fi; \
            done;

            cout warning "Wrong Answer :("
            printf "\nDo you want to check the mismatches? (y/n) "
            read -n 1 opt

            if [[ ${opt} == "y" || ${opt} == "Y" ]]; then
                vimdiff ${MDS_OUTPUT} ${test_src_folder}/test_output_${i}.txt
            else
                echo ""
                cout info "Ok, don't worry."
                echo ""
            fi
            exit 0
        fi
    done
    cout success "ALL TESTS PASSED!"
}
