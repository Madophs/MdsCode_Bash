#!/bin/bash

CPPSTD="-std=c++17"
CPPFLAGS=" -Wall -Wextra -g"
AVAIL_FLAGS=(-O3 -Wall -pipe -pthread -Wextra -g)
CANCEL="NO"
MENU_CPP_TEMPLATES=()

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
    exit 1;
fi

function input_file_name() {
    FILENAME=$(whiptail --inputbox "Filename:" 10 100 3>&1 1>&2 2>&3)
    if [[ -z $FILENAME ]]
    then
        cout error "Exiting: you didn't specified a filename."
        exit 1
    fi
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
    CHOICES=$(whiptail --title "Select your flags" --separate-output --checklist -- "" 15 35 6 \
    "0" "${AVAIL_FLAGS[0]}" OFF \
    "1" "${AVAIL_FLAGS[1]}" ON \
    "2" "${AVAIL_FLAGS[2]}" OFF \
    "3" "${AVAIL_FLAGS[3]}" OFF \
    "4" "${AVAIL_FLAGS[4]}" ON \
    "5" "${AVAIL_FLAGS[5]}" ON 3>&1 1>&2 2>&3)

    if [ -z "$CHOICES" ]; then
        CANCEL="YES"
    else
        CPPFLAGS=
        for CHOICE in $CHOICES; do
            case "$CHOICE" in
            "0")
                CPPFLAGS="${CPPFLAGS} ${AVAIL_FLAGS[0]}"
            ;;
            "1")
                CPPFLAGS="${CPPFLAGS} ${AVAIL_FLAGS[1]}"
            ;;
            "2")
                CPPFLAGS="${CPPFLAGS} ${AVAIL_FLAGS[2]}"
            ;;
            "3")
                CPPFLAGS="${CPPFLAGS} ${AVAIL_FLAGS[3]}"
            ;;
            "4")
                CPPFLAGS="${CPPFLAGS} ${AVAIL_FLAGS[4]}"
            ;;
            "5")
                CPPFLAGS="${CPPFLAGS} ${AVAIL_FLAGS[5]}"
            ;;
            *)
            echo "Unsupported item $CHOICE!" >&2
            exit 1
            ;;
            esac
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

function menu_cpp_templates() {
    TEMPLATE_CHOICE=$(whiptail --title "Templates" --menu -- "" 18 100 10 "${MENU_CPP_TEMPLATES[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$TEMPLATE_CHOICE" ]; then
        CANCEL="YES"
    else
        TEMPLATE=${TEMPLATE_CHOICE}
        menu_cpp_setup
    fi
}

function menu_cpp_setup() {
    CHOICE_CPP_SETUP=$(whiptail --title "C++ Setup" --menu -- "" 18 100 10 \
    "C++ Standard " "${CPPSTD}" \
    "Compile flags " "${CPPSTD}${CPPFLAGS}" \
    "Template" "${TEMPLATE}" \
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
        input_file_name
        set_filetype
        set_default_template
        menu_language_flags
    fi
}

function export_flags() {
    echo "${CPPSTD}${CPPFLAGS}" > ${TEMP_FLAGS_FILE}
}

function start_gui() {
    FILE_TYPE="cpp"

    set_newt_colors
    preload_cpp_templates

    menu_create_file

    GUI="N"

    if [[ ${CANCEL} == "NO" ]]
    then
        export_flags
        # Let's keep simple and run the command again with the params
        ${SCRIPT_DIR}/mdscode -n $FILENAME -f $FILE_TYPE -p $TEMPLATE
    fi
}

