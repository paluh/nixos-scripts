#!/bin/bash

#
# To be written
#
# Wrapper script for calling other scripts like so:
#
#   nix-script diff-generations 1 2
#
# So the "diff-generations" script looks like a command for "nix-script"
#

usage() {
    cat <<EOS >&2
    $(basename $0) [options] <command> <commandoptions>

    -l | --list-commands    List all available commands
    -c | --config           Use alternative configuration (rc) file
    -v                      Be verbose
    -h                      Show this help and exit

    (c) 2015 Matthias Beyer
    GPLv2 licensed
EOS
}

stderr() {
    echo "[$(basename $0)]: $*" >&2
}

script_for() {
    echo "$(dirname ${BASH_SOURCE[0]})/nix-script-${1}.sh"
}

VERBOSE=0
CONFIGFILE=~/.nixscriptsrc

cmd="$1"; shift

case $cmd in
"--list-commands" )
    LIST_COMMANDS=1
    shift;
    ;;

"-l" )
    LIST_COMMANDS=1
    shift;
    ;;

"--config" )
    CONFIGFILE=$1
    shift
    ;;

"-c" )
    CONFIGFILE=$1
    shift
    ;;

"-v" )
    export VERBOSE=1
    shift;
    ;;

"-h" )
    usage()
    exit 1
    ;;
esac

[[ ! -f $CONFIGFILE ]] && echo "No config file: '$CONFIGFILE'" && exit 1

if [[ $LIST_COMMNADS -eq 1 ]]
then
    for cmd in $(all_commands)
    do
        echo "$cmd"
    done
    exit 0
fi

exec nixos-scripts-$cmd $*
