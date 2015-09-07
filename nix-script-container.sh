#!/usr/bin/env bash

# Level-2 wrapper to be able to
#
#   nix-script container <command>

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

export VERBOSE

usage() {
    cat <<EOS >&2
    $(help_synopsis "${BASH_SOURCE[0]}" "[-h] [-l] <command>")

    -l  List all available commands
    -h  Show this help and exit

$(help_end "container")
EOS
}

while getopts "hl" OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;

        l)
            caller_util_list_subcommands_for "nix-script-container"
            exit 0
            ;;
        *)
            ;;
    esac
done

[[ -z "$1" ]] && stderr "No command given" && usage && exit 1

SCRIPT=$(caller_util_get_script "nix-script-container" "$1")
[[ -z "$SCRIPT" ]] && exit 1
stdout "SCRIPT = $SCRIPT"

stdout "Parsing args for '$1'"
SCRIPT_ARGS=$(echo $* | sed -r "s/(.*)$1(.*)/\2/")

stdout "Calling: '$SCRIPT $SCRIPT_ARGS'"
RC_CONFIG=$RC_CONFIG RC_NIXPKGS=$RC_NIXPKGS exec bash $SCRIPT $SCRIPT_ARGS

