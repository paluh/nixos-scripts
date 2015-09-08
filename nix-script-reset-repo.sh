#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS >&2
    $(help_synopsis "${BASH_SOURCE[0]}" "[-y] [-b] [-c <name>] [-w <repo>]")

    -y        | Don't ask questions
    -b        | Don't create a branch
    -c <name> | Use this name for the branch instead of "nixos-reset"
    -w <repo> | Do it in this path
    -h        | Show this help and exit

    Resets the repository in the current directory (or the directory passed with
    -w) to the current nixos version (after checking out a branch).

    Example usage:

        nix-script -v reset-repo -b -w /home/m/nixpkgs

$(help_end)
EOS
}

REPO=$RC_NIXPKGS
BRANCH="nixos-reset"
DO_BRANCH=1
QUESTIONS=1

while getopts "ybc:w:h" OPTION
do
    case $OPTION in

        y)
            QUESTIONS=0
            dbg "QUESTIONS = $QUESTIONS"
            ;;

        b)
            DO_BRANCH=0
            dbg "DO_BRANCH = $DO_BRANCH"
            ;;

        c)
            BRANCH=$OPTARG
            dbg "BRANCH = $BRANCH"
            ;;

        w)
            REPO=$OPTARG
            dbg "REPO = $REPO"
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

if [[ $DO_BRANCH -eq 1 ]]
then
    stdout "Branching new branch: $BRANCH"
    __git "$REPO" checkout -b $BRANCH
fi

if [[ $QUESTIONS -eq 1 ]]
then
    export GIT_CONFIRM=1
fi

__git "$REPO" reset --hard $(nixos-version | awk -F. '{print $3}' | awk '{print $1}')
stdout "Ready."

