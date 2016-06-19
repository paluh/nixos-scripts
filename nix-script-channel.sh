#!/usr/bin/env bash

# Level-2 wrapper to be able to
#
#   nix-script channel <command>

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

export VERBOSE

usage() {
    cat <<EOS >&2
    $(help_synopsis "${BASH_SOURCE[0]}" "[-h] [-l] <command>")

    -l  List all available commands
    -h  Show this help and exit

$(help_end "channel")
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
            caller_util_list_subcommands_for "nix-script-channel"
            exit 0
            ;;
        *)
            ;;
    esac
done

if [[ -z "$1" ]]
then
    # no command available
    stderr "No command given"
    usage
    exit 1
fi

SCRIPT=$(caller_util_get_script "nix-script-channel" "$1")
[[ -z "$SCRIPT" ]] && exit 1
stdout "SCRIPT = $SCRIPT"

stdout "Parsing args for '$1'"
SCRIPT_ARGS=$(echo $* | sed -r "s/(.*)$1(.*)/\2/")

[[ -f "$RC" ]] && { dbg "Config file found. Sourcing: '$RC'"; source $RC; }

stdout "Calling: '$SCRIPT $SCRIPT_ARGS'"
RC=$RC RC_CONFIG=$RC_CONFIG RC_NIXPKGS=$RC_NIXPKGS exec bash $SCRIPT $SCRIPT_ARGS
