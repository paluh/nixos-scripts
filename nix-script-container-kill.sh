#!/usr/bin/env

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS >&2
    $(help_synopsis "container" "kill [-h] [-n <container name>] [-d] [-- <name...>]")

    -n <name>     | Container name (only one)
    -d            | Destroy the containers, too
    -h            | Show this help and exit

    You can pass a single name with -n <name> or pass several names after two
    dashes. Everything after the dashes will be treated as container name. If
    there is an invalid name, the operation is aborted.

$(help_end)
EOS
}

NAMES=""
[[ $(echo $* | grep "\-\-") ]] && NAMES=$(echo $* | sed -r 's,(.*)\-\-(.*),\2,')

while getopts "n:d:h" OPTION
do
    case $OPTION in
        n)
            [[ ! -z "$NAMES" ]] && \
                stderr "Names given. No single name allowed" && exit 1

            NAMES=$OPTARG
            dbg "NAMES = $NAMES"
            ;;

        d)
            DESTROY=1
            dbg "DESTROY = $DESTROY"
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

containers=$(sudo nixos-container list)

for name in $NAMES
do
    if [[ $(echo $containers | grep $name) ]]
    then
        dbg "Found container: $name"
    else
        stderr "'$name' is not a container, aborting operation"
        exit 1
    fi
done

stdout "Shutting down containers..."
for name in $NAMES
do
    stdout "Shutting down container '$name'"
    explain sudo nixos-container stop $name
done
stdout "Done with shutting down containers"

stdout "Destroying containers..."
if [[ $DESTROY -eq 1 ]]
then
    for name in $NAMES
    do
        stdout "Destroying container '$name'"
        explain sudo nixos-container destroy $name
    done
fi
stdout "Done with destroying containers"

