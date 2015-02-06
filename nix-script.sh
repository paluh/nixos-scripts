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

SHIFT_ARGS=0
shift_one_more() {
    SHIFT_ARGS=$(( SHIFT_ARGS + 1 ))
}

shift_n() {
    for n in `seq 0 $1`; do shift; done
    echo $*
}

VERBOSE=0
CONFIGFILE=~/.nixscriptsrc

for cmd
do
    case $cmd in
    "--list-commands" )
        LIST_COMMANDS=1
        shift_one_more
        ;;

    "-l" )
        LIST_COMMANDS=1
        shift_one_more
        ;;

    "--config" )
        CONFIGFILE=$1
        shift_one_more
        ;;

    "-c" )
        CONFIGFILE=$1
        shift_one_more
        ;;

    "-v" )
        export VERBOSE=1
        shift_one_more
        ;;

    "-h" )
        usage()
        exit 1
        ;;

    * )
        if [ ! -n $(script_for $cmd) ]
        then
            stderr "Unknown flag / command '$cmd'"
            exit 1
        else
            if [ -z "$COMMAND" ]
            then
                COMMAND=$cmd
                shift_one_more
            else
                stderr "Found two commands, cannot execute two commands."
                exit 1
            fi
        fi
    esac
done

[[ ! -f $CONFIGFILE ]] && echo "No config file: '$CONFIGFILE'" && exit 1

if [[ $LIST_COMMNADS -eq 1 ]]
then
    for cmd in $(all_commands)
    do
        echo "$cmd"
    done
    exit 0
fi

COMMAND_ARGS=$(shift_n $SHIFT_ARGS $*)

exec $(script_for $COMMAND)
