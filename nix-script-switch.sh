#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

CONFIG_DIR=

COMMAND="switch"

usage() {
    cat <<EOS

    $(help_synopsis "${BASH_SOURCE[0]}" "[-h] [-c <command>] [-w <working directory>] [-- args...]")

        -c <command>    Command for nixos-rebuild. See 'man nixos-rebuild' (default: switch)
        -w <path>       Path to your configuration git directory (default: '$RC_CONFIG')
        -n              DON'T include hostname in tag name
        -t <tagname>    Custom tag name
        -p <pkgs>       Generate the switch tag in the nixpkgs at <pkgs> as well. (default: '$RC_NIXPKGS')
        -f <tag-flags>  Flags for git-tag (see 'git tag --help') (default: '$RC_SWITCH_DEFAULT_TAG_FLAGS')
        -b              Do not call nixos-rebuild at all.
        -h              Show this help and exit

        This command helps you rebuilding your system and keeping track
        of the system generation in the git directory where your
        configuration.nix lives. It generates a tag for each sucessfull
        build of a system. So everytime you rebuild your system, this
        script creates a tag for you, so you can revert your
        configuration.nix to the generation state.

        Example usage:

            # To rebuild the system with "nixos-rebuild switch" (by -c
            # switch), tag in /home/me/config and include the hostname
            # in the tag as well (helpful if your configuration is
            # shared between hosts).
            # Verbosity is on here.
            nix-script -v switch -c switch -w /home/me/config -n

        Everything after a double dash (--) will be passed to nixos-rebuild as
        additional parameters. For example:

            nix-script switch -c switch -- -I nixpkgs=/home/user/pkgs

        can be used to use your local clone of the nixpkgs repository.

$(help_rcvars                                                       \
    "RC_CONFIG  - Path of your system configuration (git) directory"\
    "RC_NIXPKGS - Path of your nixpkgs clone"                       \
    "RC_SWITCH_DEFAULT_TAG_FLAGS            - Default git-tag flags for tagging in system configuration (git) directory"\
    "RC_SWITCH_DEFAULT_TAG_FLAGS_NIXPKGS    - Default git-tag flags for tagging in nixpkgs"
)

$(help_end)
EOS
}

COMMAND=
ARGS=
WD=$RC_CONFIG
TAG_NAME=
HOSTNAME="$(hostname)"
NIXPKGS=$RC_NIXPKGS
TAG_FLAGS="$RC_SWITCH_DEFAULT_TAG_FLAGS"
TAG_FLAGS_NIXPKGS="$RC_SWITCH_DEFAULT_TAG_FLAGS_NIXPKGS"
DONT_BUILD=

while getopts "c:w:t:nbp:f:h" OPTION
do
    case $OPTION in
        c)
            COMMAND=$OPTARG
            dbg "COMMAND = $COMMAND"
            ;;
        w)
            WD=$OPTARG
            dbg "WD = $WD"
            ;;
        t)
            TAG_NAME=$OPTARG
            dbg "TAG_NAME = $TAG_NAME"
            ;;

        n)
            HOSTNAME=""
            dbg "HOSTNAME disabled"
            ;;

        p)
            NIXPKGS=$OPTARG
            dbg "NIXPKGS = $NIXPKGS"
            ;;

        f)
            TAG_FLAGS=$OPTARG
            dbg "TAG_FLAGS = $TAG_FLAGS"
            ;;

        b)
            DONT_BUILD=1
            dbg "DONT_BUILD = $DONT_BUILD"
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

#
# Function to generate the tag at $NIXPKGS as well
#
tag_nixpkgs() {
    if [[ ! -d "$1" ]]
    then
        stderr "'$1' is not a directory, so can't be a nixpkgs clone"
        return
    fi

    commit=$(nixos-version | cut -d . -f 3 | cut -d " " -f 1)

    c_txt="Trying to create tag '$TAG_NAME' at '$1' on commit '$commit'"
    continue_question "$c_txt" || return

    __git "$1" tag $TAG_FLAGS_NIXPKGS "$TAG_NAME" $commit || \
        stderr "Could not create tag in nixpkgs clone"
}

ARGS=$(echo $* | sed -r 's/(.*)(\-\-(.*)|$)/\2/')
dbg "ARGS = $ARGS"

[[ -z "$WD" ]] && \
    stderr "No configuration git directory." && \
    stderr "Won't do anything" && exit 1

[[ ! -d "$WD" ]]        && stderr "No directory: $WD" && exit 1
[[ -z "$COMMAND" ]]     && COMMAND="switch"

if [[ -z "$DONT_BUILD" ]]
then
    explain sudo nixos-rebuild $COMMAND $ARGS
    REBUILD_EXIT=$?
else
    stdout "Do not call nixos-rebuild"
    REBUILD_EXIT=0
fi

if [[ $REBUILD_EXIT -eq 0 ]]
then
    LASTGEN=$(current_system_generation)
    sudo -k

    stdout "sudo -k succeeded"
    stdout "Last generation was: $LASTGEN"

    if [[ -z "$TAG_NAME" ]]
    then
        if [[ -z "$HOSTNAME" ]]; then TAG_NAME="nixos-$LASTGEN-$COMMAND"
        else TAG_NAME="nixos-$HOSTNAME-$LASTGEN-$COMMAND"
        fi
    fi

    __git "$WD" tag $TAG_FLAGS "$TAG_NAME"

    if [[ ! -z "$NIXPKGS" ]]
    then
        stdout "Trying to generate tag in $NIXPKGS"
        tag_nixpkgs "$NIXPKGS"
    fi

else
    stderr "Switching failed. Won't executing any further commands."
    exit $REBUILD_EXIT
fi

