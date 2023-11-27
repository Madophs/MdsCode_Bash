#!/bin/bash

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

function create_test() {
    if [[ $(is_digit ${NO_TEST}) == NO ]]
    then
        cout error "Invalid value [${NO_TEST}]"
    fi

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

    local editor_split_cmd_format=${CONFIGS_MAP['EDITOR_SPLIT_COMMAND']}
    local end_test_num=$(( ${start_test_num} + ${NO_TEST} ))
    for (( i=${start_test_num}; i < ${end_test_num}; i+=1 ))
    do
        local file1=${test_src_folder}/test_input_${i}.txt
        local file2=${test_src_folder}/test_output_${i}.txt
        local editor_split_cmd=$(echo "${editor_split_cmd_format}" | sed -e "s|{{FILE1}}|${file1}|g" -e "s|{{FILE2}}|${file2}|g")
        eval "${editor_split_cmd}"
    done
}

function set_nth_test_as_input() {
    : ${CWSRC_FILE:=$(get_last_source_file)}
    local test_src_folder_name=$(echo ${CWSRC_FILE} | sed 's/\./_/g')
    local test_src_folder=${TEST_DIR}/${test_src_folder_name}
    local target_test=${test_src_folder}/test_input_${SET_TEST_INDEX}.txt
    if [[ -f ${target_test} ]]
    then
        cat ${target_test} > ${MDS_INPUT}
    else
        cout error "Test not found."
    fi
}

function testing() {
    : ${CWSRC_FILE:=$(get_last_source_file)}
    local test_src_folder_name=$(echo ${CWSRC_FILE} | sed 's/\./_/g')
    local test_src_folder=${TEST_DIR}/${test_src_folder_name}
    local no_test=$(( $(ls -l ${test_src_folder}/test*txt | wc -l) / 2 ))

    if [[ ${no_test} < ${STARTING_TEST} ]]
    then
        cout error "Test index out of bounds."
    fi

    for (( i=${STARTING_TEST}; i < ${no_test}; i+=1 ))
    do
        cout info "Test case #${i}"
        execute ${test_src_folder}/test_input_${i}.txt
        diff ${MDS_OUTPUT} ${test_src_folder}/test_output_${i}.txt > /dev/null
        if [[ $? != 0 ]]
        then
            cout fault "Failed Test case #${i}"
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

            if [[ ${opt} == "y" || ${opt} == "Y" ]]
            then
                local correct_output=${test_src_folder}/test_output_${i}.txt
                local editor_diff_cmd=$(echo "${CONFIGS_MAP['EDITOR_DIFF_COMMAND']}" | sed -e "s|{{FILE1}}|${correct_output}|g" -e "s|{{FILE2}}|${MDS_OUTPUT}|g")
                eval "${editor_diff_cmd}"
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
