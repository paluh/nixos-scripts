#!/usr/bin/env bash

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS
    $(help_synopsis "${BASH_SOURCE[0]}" "[-h] -p <pkg>")

        -p <pkg> | Package to download source and deps for
        -Q       | No build output
        -h       | Show this help and exit

    Download sources for the package <pkg>, so we can disconnect
    from the internet before building it.

$(help_end)
EOS
}

PACKAGE=""

while getopts "p:Qh" OPTION
do
    case $OPTION in
        p)
            PACKAGE=$OPTARG
            dbg "PACKAGE = $PACKAGE"
            ;;

        Q)
            NO_BUILD_OUTPUT=1
            dbg "NO_BUILD_OUTPUT = $NO_BUILD_OUTPUT"
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

[[ -z "$PACKAGE" ]] && stderr "No package passed" && usage && exit 1

continue_question "Install sources for package '$PACKAGE'"

drvs=$(nix-store -qR $(nix-instantiate '<nixpkgs>' -A $PACKAGE) | grep '.drv$')

ARGS=""
[[ $NO_BUILD_OUTPUT -eq 1 ]] && ARGS="-Q"

nix-store $ARGS -r $(grep -l outputHash $drv)

