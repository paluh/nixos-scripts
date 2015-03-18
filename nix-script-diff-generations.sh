#!/usr/bin/env bash

Color_Off='\e[0m'
Red='\e[0;31m'

if [[ -z "$1" || -z "$2" ]]
then
    echo "Not enough arguments, expecting two numbers (generations)"
    exit 1
fi

LOC=/nix/var/nix/profiles/per-user/$USER
TYPE=profile

DIR_A=$LOC/$TYPE-$1-link
DIR_B=$LOC/$TYPE-$2-link

if [[ ! -e $DIR_A || ! -e $DIR_B ]]
then
    echo -e "${Red}Either generation $1 or $2 does not exist.${Color_Off}"
    exit 1
fi

versA=$(mktemp)
nix-store -qR $DIR_A > $versA

versB=$(mktemp)
nix-store -qR $DIR_B > $versB

diff -u $versA $versB | grep "nix/store" | sed 's:/nix/store/: :' | \
    grep -E "^(\+|\-).*" | sed -r 's:(.) ([a-z0-9]*)-(.*):\1 \3:' | \
        sort -k 1.44
