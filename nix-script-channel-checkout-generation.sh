#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "channel" "checkout-generation [-h] [-g <n>]")

        -g <n>  Generation to checkout
        -h      Show this help and exit

$(help_end "channel")
EOS
}

# no generation by now
GEN=

while getopts "hg:" OPTION
do
    case $OPTION in
        g)
            GEN=$OPTARG
            stdout "GEN = $GEN"
            ;;
        h)
            usage
            exit 0
            ;;

        *)
            ;;
    esac
done

[[ -z "$GEN" ]] && stderr "No generation number passed" && exit 1

CHANNELS=/nix/var/nix/profiles/per-user/root/channels

stdout "Executing checkout. Password cache will be reset afterwards"
explain sudo nix-env -p $CHANNELS --switch-generation $GEN

stdout "Resetting sudo password"
sudo -k

