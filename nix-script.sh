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
