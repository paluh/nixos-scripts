#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

Color_Off='\e[0m'
Red='\e[0;31m'

usage() {
    cat <<EOS >&2
    $(help_synopsis "channel" "list-generations [-h]")

    -h      | Show this help and exit

$(help_end "channel")
EOS
}

while getopts "h" OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;
        *)
            ;;
    esac
done

stdout "Done with argument parsing"

explain sudo nix-env -p /nix/var/nix/profiles/per-user/root/channels --list-generations
