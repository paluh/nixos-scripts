#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    diff-generations [options] <generation a> <generation b>

        -s       Use system generation for diffing
        -u       Use system generation for diffing
        -n a..b  Diff these generations
        -v       Be verbose
        -h       Show this help and exit

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

            stdout "Parsing generations: $OPTARG"
            stdout "Parsing generations: GEN_A: $GEN_A"
            stdout "Parsing generations: GEN_B: $GEN_B"

            if [[ -z "$GEN_A" || -z "$GEN_B" ]]
            then
                stderr "Parsing error for '$OPTARG'"
                usage
                exit 1
            fi
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

gen_path() {
    if [[ $__SYSTEM -eq 1 ]]
    then
        echo "/nix/var/nix/profiles/system-${1}-link"
    fi

    if [[ $__USER -eq 1 ]]
    then
        echo "/nix/var/nix/profiles/per-user/$USER/profile-${1}-link"
    fi
}

DIR_A=$(gen_path $GEN_A)
DIR_B=$(gen_path $GEN_B)

stdout "VERBOSE         : $VERBOSE"
stdout "SYSTEM          : $__SYSTEM"
stdout "USER            : $__USER"
stdout "Generation A    : $GEN_A"
stdout "from directory  : $DIR_A"
stdout "Generation B    : $GEN_B"
stdout "from directory  : $DIR_B"

if [[ -z "$GEN_A" || -z "$GEN_B" ]]
then
    stderr "No generations"
    exit 1
fi

if [[ ! -e $DIR_A ]]
then
    stderr "Generation $GEN_A does not exist."
    exit 1
fi

if [[ ! -e $DIR_B ]]
then
    stderr "Generation $GEN_B does not exist."
    exit 1
fi

versA=$(mktemp)
stdout "TMP file '$versA' created"
nix-store -qR $DIR_A > $versA
stdout "Generation packages written for $GEN_A"


versB=$(mktemp)
stdout "TMP file '$versB' created"
nix-store -qR $DIR_B > $versB
stdout "Generation packages written for $GEN_B"

stdout "Diffing now..."

diff -u $versA $versB | grep "nix/store" | sed 's:/nix/store/: :' | \
    grep -E "^(\+|\-).*" | sed -r 's:(.) ([a-z0-9]*)-(.*):\1 \3:' | \
        sort -k 1.44

stdout "Removing tmp directories"

rm $versA
rm $versB

stdout "Ready"

