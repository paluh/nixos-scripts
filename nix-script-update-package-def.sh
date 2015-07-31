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
    $(help_synopsis "${BASH_SOURCE[0]}" "[-y] [-b] [-c] [-g <nixpkgs path>] -u <url>")

        -y          Don't ask before executing things (optional) (not implemented yet)
        -b          Also test-build the package (optional)
        -u <url>    Download and apply this url
        -g <path>   Path of nixpkgs clone (defaults to ./)
        -c          Don't check out another branch for update
        -d          Don't checkout base branch after successfull run.
        -h          Show this help and exit

        Helper for developers of Nix packages.

        With this command you can
            - Download package update diffs
            - Create package update commits on a new branch
            - Test build the updated package
        and everything in one step. All you need is the URL of the
        patch.

        The script asks before building the package, so you can abort if
        the script fails to find the package name.

        You really should base the update branch on the commit your
        current system is based on. This way you don't need to rebuild
        the whole world.

        Example usage:

            # Create in the current directory (which should be a clone
            # of the nixpkgs repo) a new branch for updateing ffmpeg,
            # download the patch and apply it (commit message gets generated
            # for you) and then test build it.
            # Verbosity is on.
            nix-script -v update-package-def -b -u http://monitor.nixos.org/patch?p=ffmpeg-full&v=2.7.1&m=Matthias+Beyer

$(help_end)
EOS
}

YES=0
TESTBUILD=0
NIXPKGS=
URL=
CHECKOUT=1
DONT_CHECKOUT_BASE=

while getopts "ybu:g:cdh" OPTION
do
    case $OPTION in
        y)
            YES=1
            dbg "Setting YES"
            ;;

        b)
            TESTBUILD=1
            dbg "Test-building enabled"
            ;;

        u)
            URL="$OPTARG"
            dbg "URL = $URL"
            ;;

        g)
            NIXPKGS="$OPTARG"
            dbg "NIXPKGS = $NIXPKGS"
            ;;

        c)
            CHECKOUT=0
            stdout "CHECKOUT = $CHECKOUT"
            ;;

        d)
            DONT_CHECKOUT_BASE=1
            stdout "DONT_CHECKOUT_BASE = $DONT_CHECKOUT_BASE"
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
dbg "TMP = $TMP"

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

[[ $CHECKOUT == 1 ]] && __git "$NIXPKGS" checkout -b update-$PKG || true

if [[ $? -ne 0 ]]
then
    stderr "Switching to branch update-$PKG failed."
    exit 1
fi

cat $TMP | __git "$NIXPKGS" am

if [[ $? -eq 0 ]]
then
    stdout "Patch applied."
else
    stderr "Patch apply failed. I'm exiting now"
    exit 1
fi

if [[ $TESTBUILD -eq 1 ]]
then
    ask_execute "Build '$PKG' in nixpkgs clone at '$NIXPKGS'" nix-build -A $PKG -I $NIXPKGS
fi

#
# If we checked out a new branch, we go back, too.
#
if [[ $CHECKOUT == 1 && -z "$DONT_CHECKOUT_BASE" ]]
then
    stdout "Switching back to old commit which was current before we started."
    stdout "Switching to '$CURRENT_BRANCH'"
    __git "$NIXPKGS" checkout $CURRENT_BRANCH

    if [[ $? -ne 0 ]]
    then
        stderr "Switching back to '$CURRENT_BRANCH' failed. Please check manually"
        exit 1
    fi
fi

