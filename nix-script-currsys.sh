#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "${BASH_SOURCE[0]}" "[-b] [-h]")

        -b       Check whether the current system is the booted one
        -h       Show this help and exit

    Utilities to get information from the current system

$(help_end "${BASH_SOURCE[0]}")
EOS
}

__IS_BOOTED=0

while getopts "bh" OPTION
do
    case $OPTION in

        b)
            __IS_BOOTED=1
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

link_to_path() {
    sed 's,.*\ ->\ ,,'
}

roots() {
    nix-store --gc --print-roots
}

CURRENT_SYSTEM=$(roots | grep current-system | link_to_path)

if [[ $__IS_BOOTED -eq 1 ]]; then
    booted=$(roots | grep booted-system | link_to_path)
    if [[ $booted == $current ]]; then
        echo "Booted == Current"
    else
        echo "Booted != Current"
    fi
fi

