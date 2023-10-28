#!/bin/bash

CPPSTD="-std=c++17"
CPPFLAGS=" -Wall -Wextra -D__MDS_DEBUG__ -fsanitize=address -fsanitize=undefined -fsanitize=float-cast-overflow -fsanitize=leak"

AVAIL_FLAGS=(-O3 -Wall -pipe -pthread -Wextra -g -fsanitize=address \
    -fsanitize=undefined -fsanitize=float-cast-overflow \
    -fsanitize=leak -D__MDS_DEBUG__)

MENU_CPP_FLAGS=()
CANCEL="NO"
MENU_CPP_TEMPLATES=()

TEST_CASES_SET=("New test" "" "Go back" "")
TEST_CASES_ARE_SET="NO"

function is_vim_the_father() {
    CHILD=$(ps $$ | tail -n 1 | awk '{print $1}')
    PARENT=
    while true
    do
        PARENT=$(ps -o ppid -p ${CHILD} | tail -n 1 | awk '{print $1}')
        COMMAND=$(ps -o command -p ${PARENT} | tail -n 1 | awk -F / '{print $NF}' | awk '{print $1}')
        if [[ ${PARENT} == 1 ]]
        then
            echo "NO"
            break
        elif [[ ${COMMAND} == "vim" || ${COMMAND} == "nvim" ]]
        then
            echo "YES"
            break
        fi
        CHILD=${PARENT}
    done
}

# https://askubuntu.com/questions/776831/whiptail-change-background-color-dynamically-from-magenta
function set_newt_colors() {
    USING_VIM=$(is_vim_the_father)
    if [[ ${USING_VIM} == "YES" ]]
    then
        export NEWT_COLORS='
        root=black,black
        window=lightgray,lightgray
        border=white,black
        entry=white,black
        textbox=white,black
        button=black,red
        title=white,black
        checkbox=white,black
        actsellistbox=white,black
        '
    else
        export NEWT_COLORS='
        root=black,black
        window=lightgray,lightgray
        border=white,gray
        entry=white,gray
        textbox=white,gray
        button=black,red
        title=white,gray
        checkbox=white,gray
        '
    fi
}


if [[ ! -x $(which whiptail) ]]
then
    cout error "Please install whiptail package to use interactive mode"
fi

function input_file_name() {
    FILENAME=$(whiptail --inputbox "Filename:" 10 100 3>&1 1>&2 2>&3)
    if [[ -z $FILENAME ]]
    then
        cout error "Exiting: you didn't specified a filename."
    fi
    apply_naming_convention
}

function menu_cpp_version() {
    CPPSTD=$(whiptail --title "C++ Standard" --menu -- "" 18 100 10 \
    "-std=c++2a" "" \
    "-std=c++17" "" \
    "-std=c++14" "" \
    "-std=c++11" "" \
    "-std=c++98" "" 3>&1 1>&2 2>&3)

    if [ -z "$CPPSTD" ]; then
        CANCEL="YES"
    else
        menu_cpp_setup
    fi
}

function menu_cpp_flags() {
    CHOICES=$(whiptail --title "Select your flags" --separate-output --checklist -- "" 18 55 10 "${MENU_CPP_FLAGS[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$CHOICES" ]; then
        CANCEL="YES"
    else
        CPPFLAGS=
        for CHOICE in $CHOICES; do
            CPPFLAGS="${CPPFLAGS} ${AVAIL_FLAGS[${CHOICE}]}"
        done
        menu_cpp_setup
    fi
}

function preload_cpp_templates() {
    AVAIL_TEMPLATES=($(ls -l ${TEMPLATES_DIR}/*${FILE_TYPE} | awk -F '/' '{print $NF}'))

    MENU_CPP_TEMPLATES=()
    for ITEM in "${AVAIL_TEMPLATES[@]}"
    do
        MENU_CPP_TEMPLATES+=(${ITEM})
        MENU_CPP_TEMPLATES+=("")
    done
}

function preload_cpp_flags() {
    MENU_CPP_FLAGS=()
    INDEX=0
    for ITEM in "${AVAIL_FLAGS[@]}"
    do
        MENU_CPP_FLAGS+=(${INDEX})
        MENU_CPP_FLAGS+=(${ITEM})
        AVAIL=$(echo ${CPPFLAGS} | grep -w -e "${ITEM}")
        if [[ -n ${AVAIL} ]]; then
            MENU_CPP_FLAGS+=(ON)
        else
            MENU_CPP_FLAGS+=(OFF)
        fi
        INDEX=$(( INDEX + 1 ))
    done
}

function menu_cpp_templates() {
    TEMPLATE_CHOICE=$(whiptail --title "Templates" --menu -- "" 18 100 10 "${MENU_CPP_TEMPLATES[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$TEMPLATE_CHOICE" ]; then
        CANCEL="YES"
    else
        TEMPLATE=${TEMPLATE_CHOICE}
        menu_cpp_setup
    fi
}

function load_test_cases() {
    TEST_SRC_FOLDER=${TEST_DIR}/${1}
    if [[ ! -d ${TEST_SRC_FOLDER} ]]
    then
        return
    fi
    TEST_CASES_LIST=($(ls -l ${TEST_SRC_FOLDER} | tail -n +2 | awk '{print $NF}' | grep -o -e '[0-9]*' | sort | uniq | paste -s -d ' '))
    TEST_CASES_SET=()
    for (( i=0; i < ${#TEST_CASES_LIST[@]}; i+=1 ))
    do
        TEST_CASES_SET+=("Test ${TEST_CASES_LIST[${i}]}")
        TEST_CASES_SET+=("")
        TEST_CASES_ARE_SET="YES"
    done
    TEST_CASES_SET+=("New test" "")
    TEST_CASES_SET+=("Go back" "")
}

function delete_test() {
    TEST_SRC_FOLDER=${TEST_DIR}/${1}
    TO_DELETE=${3}
    whiptail --title "Delete test case" --yesno --defaultno "Are you sure to delete Test #${TO_DELETE}?" 20 60 3>&1 1>&2 2>&3
    STATUS=$?
    if [[ ${STATUS} == 0 ]]
    then
        rm -f ${TEST_SRC_FOLDER}/test_input_${TO_DELETE}.txt &> /dev/null
        rm -f ${TEST_SRC_FOLDER}/test_output_${TO_DELETE}.txt &> /dev/null
        load_test_cases "${1}"
        align_tests "${TEST_SRC_FOLDER}"
    fi
}

function test_cases_setup_menu() {
    SRC_FOLDER_NAME=${FILENAME}_${FILE_TYPE}
    TESTCASE_CHOICE=$(whiptail --title "Test cases" --menu -- "" 18 100 10 "${TEST_CASES_SET[@]}" 3>&1 1>&2 2>&3)

    STATUS=$?
    if [[ ${STATUS} == 1 ]]
    then
        CANCEL="YES"
    else
        case ${TESTCASE_CHOICE} in
            "New test")
                mdscode -a 1 "${FILENAME}.${FILE_TYPE}"
                load_test_cases ${SRC_FOLDER_NAME}
                test_cases_setup_menu
            ;;
            "Go back")
                menu_cpp_setup
            ;;
            *)
                delete_test ${SRC_FOLDER_NAME} ${TESTCASE_CHOICE}
                test_cases_setup_menu
            ;;
        esac
    fi
}

function menu_cpp_setup() {
    CHOICE_CPP_SETUP=$(whiptail --title "C++ Setup" --menu -- "" 18 200 10 \
    "C++ Standard " "${CPPSTD}" \
    "Compile flags " "${CPPSTD}${CPPFLAGS}" \
    "Template" "${TEMPLATE}" \
    "Add test cases" "${TEST_CASES_ARE_SET}" \
    "Continue" "" 3>&1 1>&2 2>&3)

    if [ -z "$CHOICE_CPP_SETUP" ]; then
        CANCEL="YES"
    else
        case ${CHOICE_CPP_SETUP} in
            "C++ Standard ")
                menu_cpp_version
            ;;
            "Compile flags ")
                menu_cpp_flags
            ;;
            "Template")
                menu_cpp_templates
            ;;
            "Add test cases")
                test_cases_setup_menu
            ;;
        esac
    fi
}

function menu_language_flags() {
    case ${LANGUAGE} in
        "C++")
            menu_cpp_setup
            ;;
    esac
}

function set_default_template() {
    if [[ -f ${TEMPLATES_DIR}/default.${FILE_TYPE} ]]
    then
        TEMPLATE=default.${FILE_TYPE}
    else
        TEMPLATE=none
    fi
}

function set_filetype() {
    case ${LANGUAGE} in
        "C++")
            FILE_TYPE="cpp"
        ;;
        "C Language")
            FILE_TYPE="c"
        ;;
        "Java")
            FILE_TYPE="java"
        ;;
        "Python")
            FILE_TYPE="py"
        ;;
        "Rust")
            FILE_TYPE="rs"
        ;;
    esac
}

function menu_create_file() {
    LANGUAGE=$(whiptail --title "Choose your weapon" --menu "" 18 100 10 \
    "C++" "" \
    "C Language" "" \
    "Java" "" \
    "Python" "" \
    "Rust" "" 3>&1 1>&2 2>&3)

    if [ -z "$LANGUAGE" ]; then
        CANCEL="YES"
    else
        preload
        input_file_name
        set_filetype
        load_test_cases "${FILENAME}_${FILE_TYPE}"
        set_default_template
        menu_language_flags
    fi
}

function export_flags() {
    echo "${CPPSTD}${CPPFLAGS}" > ${TEMP_FLAGS_FILE}
}

function preload() {
    if [[ ${FILE_TYPE} == "cpp" ]]
    then
        preload_cpp_flags
        preload_cpp_templates
    fi
}

function start_gui() {
    clear
    set_newt_colors
    menu_create_file

    GUI="N"

    if [[ ${CANCEL} == "NO" ]]
    then
        export_flags
        # Let's keep simple and run the command again with the params
        ${SCRIPT_DIR}/mdscode -n "${FILENAME}" -f $FILE_TYPE -p $TEMPLATE
    fi
}

