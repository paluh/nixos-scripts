#!/usr/bin/env bash

Color_Off='\e[0m'
Red='\e[0;31m'
Yellow='\e[0;33m'
Green='\e[0;32m'

stderr() {
    echo -e "${Red}[$(basename $0)]: ${*}${Color_Off}" >&2
}

stdout() {
    [[ $VERBOSE -eq 1 ]] && echo -e "${Green}[$(basename $0)]:${Color_Off} $*"
}

scriptname_to_command() {
        echo "$1" | sed 's,^\.\/nix-script-,,' | sed 's,\.sh$,,'
}

help_synopsis() {
    SCRIPT=$(scriptname_to_command $1); shift
    echo "usage: nix-script $SCRIPT $*"
}

help_end() {
    echo -e "\tAdding '-v' before the '$1' command turns on verbosity"
    echo -e ""
    echo -e "\tReleased under terms of GPLv2"
    echo -e "\t(c) 2015 Matthias Beyer"
    echo ""
}

explain() {
    stdout "$*"
    $*
}

grep_generation() {
    $* | grep current | cut -d " " -f 2
}

current_system_generation() {
    grep_generation "sudo nix-env -p /nix/var/nix/profiles/system --list-generations"
}

current_user_generation() {
    grep_generation "nix-env --list-generations"
}

continue_question() {
	local answer
	echo -ne "${Yellow}$1 [yN]?:${Color_Off} " >&2
	read answer
		echo ""
	[[ "${answer}" =~ ^[Yy]$ ]] || return 1
}

__git() {
    DIR=$1; shift
    explain git --git-dir="$DIR/.git" --work-tree="$DIR" $*
}
