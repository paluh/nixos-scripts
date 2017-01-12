#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh
[[ -f "$RC" ]] && { dbg "Config file found. Sourcing: '$RC'"; source $RC; }

usage() {
    cat <<EOS
    $(help_synopsis "channel" "update [-h] [-t <name>] [-w <cfgdir>] [-n] [-N]")

        -t <name>   | Name for the new tag, instead of nixos-<host>-channel-<num>
        -n          | Add channel name (from config) in the tag name, currently: $RC_CHANNEL_NAME
        -w <cfgdir> | Alternative config dir, default: $RC_CONFIG
        -N          | DON'T include hostname in tag name
        -h          | Show this help and exit

$(help_end)
EOS
}

TAG_NAME=""
ADD_CHANNEL_NAME=0
CONFIG=$RC_CONFIG
HOST="$(hostname)"

while getopts "t:w:nNh" OPTION
do
    case $OPTION in
        t)
            TAG_NAME=$OPTARG
            dbg "TAG_NAME = $TAG_NAME"
            ;;

        n)
            ADD_CHANNEL_NAME=1
            dbg "ADD_CHANNEL_NAME = $ADD_CHANNEL_NAME"
            ;;

        w)
            CONFIG=$OPTARG
            dbg "CONFIG = $CONFIG"
            ;;

        N)
            HOST=""
            dbg "HOST = $HOST"
            ;;

        h)
            usage
            exit 0
            ;;

        *)
            ;;
    esac
done

[[ -z "$CONFIG" ]] && \
    stderr "No configuration git directory." && \
    stderr "Won't do anything" && exit 1

stdout "Updating nix-channel"
explain sudo nix-channel --update
stdout "Ready with updating"

if [[ -z "$NAME" ]]
then
    TAG_NAME="nixos-$([[ ! -z "$HOST" ]] && echo "$HOST-")channel-$(current_channel_generation)"
    stdout "Tag name: '$TAG_NAME'"
fi

if [[ $ADD_CHANNEL_NAME -eq 1 ]]; then
    [[ -z "$RC_CHANNEL_NAME" ]] && \
        stderr "RC SETTING MISSING: RC_CHANNEL_NAME" && exit 1

    dbg "Add the channel name in the tag"
    TAG_NAME="${TAG_NAME}-${RC_CHANNEL_NAME}"
    dbg "TAG_NAME = ${TAG_NAME}"
else
    dbg "Do not add the channel name in the tag"
fi

stdout "Resetting sudo password"
sudo -k

stdout "Tagging '$CONFIG' repo with tag name '$TAG_NAME'"
__git "$CONFIG" tag $TAG_NAME

