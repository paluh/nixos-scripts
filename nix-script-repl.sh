#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS >&2
    $(help_synopsis "${BASH_SOURCE[0]}" "[-h] [--shell]")

    --shell     If a command is not available, try to execute it in this shell
    -h          Show this help and exit

    All nixos-script subcommands and their respective arguments are available.

    In addition to the normal commands, these commands are available:

        list        | Lists all available commands

$(help_end "repl")
EOS
}

Color_Off='\e[0m'
Red='\e[0;31m'
Green='\e[32m'

__SHELL=0

for arg
do
    case $arg in

        --shell)
            __SHELL=1
            dbg "__SHELL = $__SHELL"
            ;;

        "-h")
            usage
            exit 0
            ;;

        *)
            ;;
    esac
done

run() {
    dbg $*; $*
}

__exists() {
    dbg "Exists '$1'? ..."
    which $1 >/dev/null 2>/dev/null
}

prompt() {
    echo -en "${Green}nix-script repl >${Color_Off} "
}

__run_if_exists() {
    [[ $(__exists $1) ]] && run $* || false
}

__list() {
    dbg "Listing commands"
    caller_util_list_subcommands_for "nix-script"
}

__verbosity() {
    case $1 in
        on)
            export VERBOSE=1
            dbg "VERBOSE = $VERBOSE"
            stdout "Verbosity is now ON"
            ;;
        off)
            export VERBOSE=0
            dbg "VERBOSE = $VERBOSE"
            stdout "Verbosity is now ON"
            ;;
        *)
            stderr "Unknown argument: $1"
            stderr "Usage: verbosity [on|off]"
            ;;
    esac
}

__debugging() {
    case $1 in
        on)
            export DEBUG=1
            dbg "DEBUG = $DEBUG"
            stdout "Debugging is now ON"
            ;;
        off)
            export DEBUG=0
            dbg "DEBUG = $DEBUG"
            stdout "Debugging is now ON"
            ;;
        *)
            stderr "Unknown argument: $1"
            stderr "Usage: debuggig [on|off]"
            ;;
    esac
}

__exit() {
    stdout "Ready. Bye-Bye!"
    [[ -z "$1" ]] && exit 0
    exit $1
}

__builtin__() {
    local str=$1; shift
    local cmd=$1; shift
    local args=$*

    [[ $COMMAND =~ $str ]] && $cmd $args && prompt
}

prompt
while read COMMAND ARGS
do
    __builtin__ "help"      usage       $ARGS  && continue
    __builtin__ "exit"      __exit      $ARGS  && continue
    __builtin__ "list"      __list      $ARGS  && continue
    __builtin__ "verbosity" __verbosity $ARGS  && continue
    __builtin__ "debugging" __debugging $ARGS  && continue

    dbg "Got '$COMMAND' with args '$ARGS'"
    stdout "Searching for script for '$COMMAND'"
    SCRIPT=$(script_for $COMMAND)

    if [[ ! -f $SCRIPT || ! -x $SCRIPT ]]
    then
        dbg "Not available or executable: $COMMAND"
        #
        # Checks whether the args include bash-specific things like || or &&, as
        # these cannot be executed by nix-script repl by now, and prints a
        # warning and does not allow execution of these.
        #
        if [[ "$ARGS" =~ ^[a-zA-Z0-9_\ ]*$ && $__SHELL -eq 1 ]]
        then
            dbg "Executing: '$COMMAND $ARGS'"
            $COMMAND $ARGS
        fi
    else
        stdout "Calling: '$COMMAND $ARGS'"
        bash $SCRIPT $ARGS
    fi
    prompt
done

