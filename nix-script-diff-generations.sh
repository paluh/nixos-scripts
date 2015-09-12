#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "${BASH_SOURCE[0]}" "[-s | -u] [-n <a..b>] [-h]")

        -s       Use system generation for diffing
        -u       Use system generation for diffing
        -n a..b  Diff these generations
        -h       Show this help and exit

    Show the diff between two generations, so the installed and removed
    packages.

    Example usage:

        # To show the diff of the system generation 123 to 145
        # with verbosity on
        nix-script -v diff-generations -s -n 123..145

$(help_end "${BASH_SOURCE[0]}")
EOS
}

__SYSTEM=0
__USER=0

GEN_A=
GEN_B=

while getopts "sun:h" OPTION
do
    case $OPTION in

        s)
            stdout "Setting profile: system"
            __SYSTEM=1
            __USER=0
            ;;

        u)
            stdout "Setting profile: user ($USER)"
            __SYSTEM=0
            __USER=1
            ;;

        n)
            GEN_A=$(echo $OPTARG | cut -d "." -f 1)
            GEN_B=$(echo $OPTARG | cut -d "." -f 3)

            dbg "Parsing generations: $OPTARG"
            dbg "Parsing generations: GEN_A: $GEN_A"
            dbg "Parsing generations: GEN_B: $GEN_B"

            [[ -z "$GEN_A" || -z "$GEN_B" ]] && \
                stderr "Parsing error for '$OPTARG'" && usage && exit 1
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

#
# Helper to generate a path for the profile we want to diff with
#
gen_path() {
    [[ $__SYSTEM -eq 1 ]] && echo "/nix/var/nix/profiles/system-${1}-link"
    [[ $__USER -eq 1 ]] && echo "/nix/var/nix/profiles/per-user/$USER/profile-${1}-link"
}

DIR_A=$(gen_path $GEN_A)
DIR_B=$(gen_path $GEN_B)

dbg "VERBOSE         : $VERBOSE"
dbg "SYSTEM          : $__SYSTEM"
dbg "USER            : $__USER"
dbg "Generation A    : $GEN_A"
dbg "from directory  : $DIR_A"
dbg "Generation B    : $GEN_B"
dbg "from directory  : $DIR_B"

#
# Error checking whether the generations exist.
#
[[ -z "$GEN_A" || -z "$GEN_B" ]] && stderr "No generations"     && exit 1
[[ ! -e $DIR_A ]] && stderr "Generation $GEN_A does not exist." && exit 1
[[ ! -e $DIR_B ]] && stderr "Generation $GEN_B does not exist." && exit 1

#
# Querying the store for the stuff in a generation A
#
versA=$(mktemp)
stdout "TMP file '$versA' created"
nix-store -qR $DIR_A | sort -t'-' -k 2 > $versA
stdout "Generation packages written for $GEN_A"

#
# Querying the store for the stuff in a generation B
#
versB=$(mktemp)
stdout "TMP file '$versB' created"
nix-store -qR $DIR_B | sort -t'-' -k 2 > $versB
stdout "Generation packages written for $GEN_B"

stdout "Diffing now..."

diff -u $versA $versB | \
    # Select only lines that differ.
    # (no context, no file name, no line number, etc.)
    grep '^[+-]/nix/store' | \
    # Remove the "/nix/store/<hash>" garbage.
    # Add a space instead, to separate the [+-] from the name.
    sed 's:/nix/store/[^-]*-: :' | \
    # sort by name, then prefer '+' over '-'.
    sort -k 2 -k 1,1r

stdout "Removing tmp directories"

rm $versA
rm $versB

stdout "Ready"

