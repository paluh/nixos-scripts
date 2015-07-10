#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

profiledir=/nix/var/nix/profiles

usage() {
    cat <<EOS >&2
    $(help_synopsis "${BASH_SOURCE[0]}" "[--system | -s] [--user | -u] [-n] [-h]")

    --system | -s           | Show system profiles
    --user | -u             | Show user profiles
    --system-profiles | -p  | Show other system profiles
    -n                      | Show only profile numbers
    -h                      | Show this help and exit

    Show the generations which are currently available for either the
    current user (-u | --user) or the current system (-s | --system)
    profile.

    Per default, this shows the link name, if you pass -n it only shows
    the numbers.

    Example usage:

        # To show the profile generations for the system generation, but
        # only the numbers.
        # With verbosity on.
        nix-script -v ls-profiles -s -n

$(help_end)
EOS
}

SYSTEM=0
USER=0
SYSPROF=0
NUMBERS=0

for arg
do

    case $arg in
        "--system" )
            SYSTEM=1
            ;;

        "-s" )
            SYSTEM=1
            ;;

        "-u" )
            USER=1
            ;;

        "--user" )
            USER=1
            USER_NAMES=$USER
            ;;

        "--system-profiles" )
            SYSPROF=1
            ;;

        "-p" )
            SYSPROF=1
            ;;

        "-n" )
            NUMBERS=1
            ;;

        "-h" )
            usage
            exit 0
            ;;

        "*")
            ;;
    esac
done

(( $SYSTEM == 0 && $USER == 0 && $SYSPROF == 0 )) && usage && exit 1

numberfilter() {
    pref="$1"
    if (( $NUMBERS == 0 ))
    then
        cat
    else
        if (( ($SYSTEM != 0 && $USER != 0) ||
              ($SYSTEM != 0 && $SYSPROF != 0) ||
              ($USER != 0 && $SYSPROF != 0) ))
        then
            cut -d - -f 2 | sort -n | sed -r "s:^(.*):$pref\1:"
        else
            cut -d - -f 2 | sort -n
        fi
    fi
}

list() {
    ls "$profiledir/$1" | grep -E "$2" | numberfilter "$3"
}

(( $SYSTEM == 1 )) && list "" "^system-.*-link" "system/"

if (( $USER == 1 ))
then
    for u in $USER_NAMES;
    do
        list "per-user/$u" "^profile-.*-link" "user/$u/"
    done
fi

if (( $SYSPROF == 1 ))
then
    for entry in $(ls "$profiledir/system-profiles" | grep -v ".*-.*-link")
    do
        list "system-profiles/" "^$entry-.*-link" "system/$entry/"
    done
fi
