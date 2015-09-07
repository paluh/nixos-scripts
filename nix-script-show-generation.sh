#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "${BASH_SOURCE[0]}" "[-s | -u | -p <profile>] [-h]")

        -s           | Show system generation
        -u           | Show user generation (default)
        -p <profile> | Show <profile> generation
        -h           | Show this help and exit

    Show the number of the current generations. Defaults to user
    profile, but system profile can be checked as well.

    Example usage:

        # To show the system generation which is current.
        # With verbosity on.
        nix-script -v show-generations -s

$(help_end)
EOS
}

SYSTEM=0
USER=1
PROFILE=""

while getopts "sup:h" OPTION
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
        p)
            SYSTEM=0
            USER=0
            PROFILE=$OPTARG
            dbg "PROFILE = $PROFILE"
            ;;

        h)
            stdout "Showing usage"
            usage
            exit 0
            ;;
    esac
done

if [[ ! -z "$PROFILE" ]]
then
    grep_generation "sudo nix-env -p /nix/var/nix/profiles/$PROFILE --list-generations"
else
    ([[ $SYSTEM -eq 1 ]] && current_system_generation) || \
        current_user_generation
fi


stdout "Ready"

