#!/usr/bin/env bash

if [[ -z "$1" || -z "$2" ]]
then
    echo "Not enough arguments, expecting two numbers (generations)"
    exit 1
fi

LOC=/nix/var/nix/profiles/per-user/$USER
TYPE=profile

versA=$(mktemp)
nix-store -qR $LOC/$TYPE-$1-link > $versA

versB=$(mktemp)
nix-store -qR $LOC/$TYPE-$2-link > $versB

diff -u $versA $versB | grep "nix/store" | sed 's:/nix/store/: :' | \
    grep -E "^(\+|\-).*" | sed -r 's:(.) ([a-z0-9]*)-(.*):\1 \3:' | \
        sort -k 1.44
