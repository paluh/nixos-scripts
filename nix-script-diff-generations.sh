#!/bin/bash

LOC=/nix/var/nix/profiles/per-user/$USER
TYPE=profile

versA=$(mktemp)
nix-store -qR $LOC/$TYPE-$1-link > $versA

versB=$(mktemp)
nix-store -qR $LOC/$TYPE-$2-link > $versB

diff -u $versA $versB | grep "nix/store" | sed 's:/nix/store/: :' | \
    sed -r 's:(.) ([a-z0-9]*)-(.*):\1 \3:' | sort -k 1.44
