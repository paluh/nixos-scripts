#!/usr/bin/env bash

#
#
# Updates a package definition by downloading the patch from monitor.nixos.org,
# creating a branch in the nixpkgs repo for it, applying the patch and
# test-building the package if you want to.
#
#

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "${BASH_SOURCE[0]}" "[-y] [-b] [-g <nixpkgs path>] -u <url>")

        -y          Don't ask before executing things (optional) (not implemented yet)
        -b          Also test-build the package (optional)
        -u <url>    Download and apply this url
        -g <path>   Path of nixpkgs clone (defaults to ./)
        -h          Show this help and exit

$(help_end)
EOS
}

YES=0
TESTBUILD=0
NIXPKGS=
URL=

while getopts "ybu:g:h" OPTION
do
    case $OPTION in
        y)
            YES=1
            stdout "Setting YES"
            ;;

        b)
            TESTBUILD=1
            stdout "Test-building enabled"
            ;;

        u)
            URL="$OPTARG"
            stdout "URL = $URL"
            ;;

        g)
            NIXPKGS="$OPTARG"
            stdout "NIXPKGS = $NIXPKGS"
            ;;

        h)
            usage
            exit 0
            ;;

    esac
done

if [ -z "$URL" ]
then
    stderr "No URL for the patch"
    exit 1
fi

if [ -z "$NIXPKGS" ]
then
    stderr "No nixpkgs passed."
    stderr "Checking whether the current directory is a git repository!"
    stderr "(this could possibly blow up pretty badly)"
    continue_question "Continue execution" || exit 1

    if [[ -d ./.git ]]
    then
        stdout "Git directory found"
        NIXPKGS="."
    else
        stderr "No git directory"
        exit 1
    fi
fi

stdout "Making temp directory"
TMP=$(mktemp)
stdout "TMP = $TMP"

stdout "Fetching patch"
curl $URL > $TMP

stdout "Parsing subject to branch name"
PKG=$(cat $TMP | grep Subject | cut -d: -f 2 | sed -r 's,(\ *)(.*)(\ *),\2,')

#translate subject line if necessary
if [[ $(cat $TMP | grep "update from") ]]
then
    sed -i -r 's;Subject\:\ (.*)\:\ update from (.*) to (.*);Subject: \1\:\ \2 \ -> \3;' $TMP
fi

CURRENT_BRANCH=$(__git_current_branch "$NIXPKGS")
__git "$NIXPKGS" checkout -b update-$PKG
if [[ $? -ne 0 ]]
then
    stderr "Switching to branch update-$PKG failed."
    exit 1
fi

cat $TMP | __git "$NIXPKGS" am
stdout "Patch applied."

if [[ $TESTBUILD -eq 1 ]]
then
    ask_execute "Build '$PKG' in nixpkgs clone at '$NIXPKGS'" nix-build -A $PKG -I $NIXPKGS
fi

stdout "Switching back to old commit which was current before we started."
stdout "Switching to '$CURRENT_BRANCH'"
__git "$NIXPKGS" checkout $CURRENT_BRANCH
if [[ $? -ne 0 ]]
then
    stderr "Switching back to '$CURRENT_BRANCH' failed. Please check manually"
    exit 1
fi

