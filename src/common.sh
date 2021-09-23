#!/bin/bash

TEMPLATES_DIR=${SCRIPT_DIR}/templates
SRC_DIR=${SCRIPT_DIR}/src
FILENAME=""
TEMP_FILE="" # Temporal file
TEMP_DIR="/tmp/mdscode"

# Global variables for naming conventions

# CASETYPE
# UCWORDS uppercase the first letter of every word
# UPPERCASE Y LOWERCASE
CASETYPE="UCWORDS" # UCWORDS upper cases first lo
WHITESPACE_REPLACE="_"

function temp_setup() {
    mkdir -p "/tmp/mdscode"
}

temp_setup
