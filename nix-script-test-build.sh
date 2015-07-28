#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "${BASH_SOURCE[0]}" "-p <pkg> [-b <branch>] [-h]")

        -p <pkg>    Test build this package
        -i <nixpkg> Nixpackages repo clone (defaults to current dir)
        -b <branch> Test build the current branch on this base
        -h          Show this help and exit

    Test-build a package by calling nix-build.
    Optionally do a rebase of the current branch onto another before
    test-building, so a PR to nixpkgs master can be test-build on nixpkgs
    unstable.

    Example usage:

        # To show the diff of the system generation 123 to 145
        # with verbosity on
        nix-script -v test-build -p firefox -b channel-unstable

$(help_end)
EOS
}

PKG=
NIXPKGS=.
BRANCH=

while getopts "p:i:b:h" OPTION
do
    case $OPTION in
        p)
            PKG=$OPTARG
            dbg "PKG = $PKG"
            ;;

        i)
            NIXPKGS=$OPTARG
            dbg "NIXPKGS = $NIXPKGS"
            ;;

        b)
            BRANCH=$OPTARG
            dbg "BRANCH = $BRANCH"
            ;;

        h)
            usage
            exit 0
            ;;

    esac
done

[[ -z "$PKG" ]] && stderr "No package given" && usage && exit 1
[[ -z "$NIXPKGS" ]] && stderr "No nixpkgs repo given" && usage && exit 1

[[ -d "$NIXPKGS" && is_git_repo "$NIXPKGS" ]] && \
    stderr "Not a nixpkgs repo: $NIXPKGS" && exit 1



nix-build -A $PKG -I $NIXPKGS

