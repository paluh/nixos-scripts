#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "${BASH_SOURCE[0]}" "[-s | -u] [-h]")

        -s       Show system generation
        -u       Show user generation (default)
        -h       Show this help and exit

$(help_end)
EOS
}

SYSTEM=0
USER=1

while getopts "suh" OPTION
do
    case $OPTION in
        s)
            SYSTEM=1
            USER=0
            stdout "Showing system generation"
            ;;
        u)
            SYSTEM=0
            USER=1
            stdout "Showing user generation"
            ;;
        h)
            stdout "Showing usage"
            usage
            exit 0
            ;;
    esac
done

([[ $SYSTEM -eq 1 ]] && current_system_generation) || current_user_generation

stdout "Ready"

