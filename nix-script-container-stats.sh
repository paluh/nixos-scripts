#!/usr/bin/env

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS >&2
    $(help_synopsis "container" "stats [-h] [-t]")

    -t | Do not print table header
    -h | Show this help and exit

$(help_end "container")
EOS
}

HEADER=1

while getopts "th" OPTION
do
    case $OPTION in
        t)
            HEADER=0
            dbg "HEADER = $HEADER"
            ;;

        h)
            usage
            exit 1
            ;;
    esac
done

stdout "Listing containers"
containers=$(sudo nixos-container list)

stdout "Building table layout"
longestname=$(echo $containers | awk '{print length}' | sort -nr | head -n 1)

__FMT_IP__=" | %-15s"
__FMT_STAT__=" | %-6s"
__FMT_HKEY__=" | %-15s"

__FORMAT__="%-${longestname}s${__FMT_IP__}${__FMT_STAT__}${__FMT_HKEY__}\n"

stdout "Ready building table layout"

stdout "Starting table"
repeat_char() {
    local str=$1
    local num=$2
    local v=$(printf "%-${num}s" "$str")
    echo "${v// /$str}"
}

[[ $HEADER -eq 1 ]] && \
    printf "$__FORMAT__" Name IP Status Host-Key && \
    printf "$__FORMAT__" "$(repeat_char "-" $longestname)"\
                         "$(repeat_char "-" 15)"\
                         "$(repeat_char "-" 6)"\
                         "$(repeat_char "-" 15)"

for name in $containers
do
    stdout "Calling nixos-container with"
    stdout "'show-ip'"
    stdout "'status'"
    stdout "'show-host-key'"
    stdout "in sudo now..."

    ip="$(sudo nixos-container show-ip $name)"
    stat="$(sudo nixos-container status $name)"
    hkey="$(sudo nixos-container show-host-key $name)"

    printf "$__FORMAT__" "$name" "$ip" "$stat" "$hkey"
done

stdout "Ready printing table"

