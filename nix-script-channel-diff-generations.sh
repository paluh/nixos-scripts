#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS >&2
    $(help_synopsis "channel" "diff-generations [-g <command>] [-w <path>] [-n <generations>] [-h]")

    -g <command>        | Use this command instead of 'diff --name-only' (currently no support for multi-word args)
    -w <path>           | Path to working-copy of nixpkgs git repo, default: $RC_NIXPKGS
    -n <generations>    | Generations to show diff in form a..b
    -h                  | Show this help and exit

$(help_end)
EOS
}

GEN_A=
GEN_B=
WC=$RC_NIXPKGS
GIT="diff --name-only"

explain() {
    stdout $*
    $*
}

while getopts "g:w:n:h" OPTION
do
    case $OPTION in
        g)
            GIT=$OPTARG
            dbg "GIT = $GIT"
            ;;

        w)
            WC=$OPTARG
            dbg "WC = $WC"
            ;;

        n)
            GEN_A=$(echo $OPTARG | cut -d "." -f 1)
            GEN_B=$(echo $OPTARG | cut -d "." -f 3)

            [[ -z "$GEN_A" || -z "$GEN_B" ]] && \
                stderr "Parsing error for '$OPTARG'" && usage && exit 1

            dbg "GEN_A = $GEN_A"
            dbg "GEN_B = $GEN_B"
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

[[ -z "$GEN_A" || -z "$GEN_B" ]] && \
    stderr "No generation information" && usage && exit 1

pathof() {
    echo "/nix/var/nix/profiles/per-user/root/channels-$1-link/nixos/nixpkgs/.version-suffix"
}

version_string() {
    local path=$(pathof $1)
    local version=$(cat $path)

    [[ -z "$version" ]] && \
        stderr "No commit version information for generation $1" && exit 1

    echo $version

}

commit_for() {
    echo $(version_string $1) | cut -d . -f 2
}

__git() {
    explain git --git-dir="$WC/.git" --work-tree="$WC" $*
}

A=$(commit_for $GEN_A)
B=$(commit_for $GEN_B)

stdout "A = $A"
stdout "B = $B"

[[ "$A" -eq "$B" ]] && \
    echo "Same hash for both generations. There won't be a diff" && exit 1

if [[ -z "$WC" ]]
then
    echo "$A..$B"
else
    __git $GIT "$A..$B"
fi

stdout "Ready"

