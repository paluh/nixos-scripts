#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "channel" "update [-h] [-t <name>] [-w <cfgdir>] [-n]")

        -t <name>   | Name for the new tag, instead of nixos-<host>-channel-<num>
        -w <cfgdir> | Alternative config dir, default: $RC_CONFIG
        -n          | DON'T include hostname in tag name
        -h          | Show this help and exit

$(help_end)
EOS
}

TAG_NAME=""
CONFIG=$RC_CONFIG
HOST="$(hostname)"

while getopts "t:w:nh" OPTION
do
    case $OPTION in
        t)
            TAG_NAME=$OPTARG
            dbg "TAG_NAME = $TAG_NAME"
            ;;

        w)
            CONFIG=$OPTARG
            dbg "CONFIG = $CONFIG"
            ;;

        n)
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

stdout "Resetting sudo password"
sudo -k

stdout "Tagging '$CONFIG' repo with tag name '$TAG_NAME'"
__git "$CONFIG" tag $TAG_NAME

