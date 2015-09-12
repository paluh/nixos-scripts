#!/usr/bin/env bash

Color_Off='\e[0m'
Red='\e[0;31m'
Yellow='\e[0;33m'
Green='\e[0;32m'

#
# Print on stderr, in red
#
stderr() {
    echo -e "${Red}[$(basename $0)]: ${*}${Color_Off}" >&2
}

#
# Print debugging output on stderr, in green
#
dbg() {
    [[ $DEBUG -eq 1 ]] && \
        echo -e "${Green}[DEBUG][$(basename $0)]: ${*}${Color_Off}" >&2
}

#
# Print on stdout, if verbosity is enabled, prefix in green
#
stdout() {
    [[ $VERBOSE -eq 1 ]] && echo -e "${Green}[$(basename $0)]:${Color_Off} $*"
}

#
# Get the command name from a script path
#
scriptname_to_command() {
    callee=$([ -z "$2" ] && echo "nix-script" || echo "$2")
    echo "$1" | sed -r "s,$(dirname ${BASH_SOURCE[0]})/$callee-(.*)\.sh$,\1,"
}

#
# Generate a help synopsis text
#
help_synopsis() {
    SCRIPT=$(scriptname_to_command $1); shift
    echo "usage: nix-script [-v] $SCRIPT $*"
}

#
# Helper for section on variables from the RC file for the script
#
help_rcvars() {
    echo -e "\tUsed nix-script.rc variables:"
    echo -e "\t-----------------------------"
    echo -e ""
    for s; do echo -e "\t\t${s}"; done
    echo -e ""
}

#
# generate a help text footnote
#
help_end() {
    echo -e "\tAdding '-v' before the '$1' command turns on verbosity"
    echo -e ""
    echo -e "\tReleased under terms of GPLv2"
    echo -e "\t(c) 2015 Matthias Beyer"
    echo ""
}

#
# Explain the next command
#
explain() {
    stdout "$*"
    $*
}

#
# Helper for greping the current generation
#
grep_generation() {
    $* | grep current | sed -r 's,\s*([0-9]*)(.*),\1,'
}

#
# get the current system generation
#
current_system_generation() {
    grep_generation "sudo nix-env -p /nix/var/nix/profiles/system --list-generations"
}

#
# get the current user generation
#
current_user_generation() {
    grep_generation "nix-env --list-generations"
}

#
# get the current channel generation
#
current_channel_generation() {
    grep_generation "sudo nix-env -p /nix/var/nix/profiles/per-user/root/channels --list-generations"
}

#
# Ask the user whether to continue or not
#
continue_question() {
	local answer
	echo -ne "${Yellow}$1 [yN]?:${Color_Off} " >&2
	read answer
		echo ""
	[[ "${answer}" =~ ^[Yy]$ ]] || return 1
}

#
# Ask whether a command should be executed or not.
#
ask_execute() {
    q="$1"; shift
	local answer
	echo -ne "${Yellow}$q${Color_Off} [Yn]? "
	read answer; echo
	[[ ! "${answer}" =~ ^[Nn]$ ]] && eval $*
}

#
# Helper for executing git commands in another git directory
#
__git() {
    DIR=$1; shift
    explain git --git-dir="$DIR/.git" --work-tree="$DIR" $*
}

# Gets the current branch name or the hash of the current rev if there is no
# branch
__git_current_branch() {
    branch_name=$(git symbolic-ref -q HEAD)
    branch_name=${branch_name##refs/heads/}
    ([[ -z "$branch_name" ]] && git rev-parse HEAD) || echo $branch_name
}

# Argument 1: Caller script name, format: "nix-script"
caller_util_all_commands() {
    find $(dirname ${BASH_SOURCE[0]}) -type f -name "${1}-*.sh"
}

# Argument 1: Caller script name, format: "nix-script"
caller_util_list_subcommands_for() {
    for cmd in $(caller_util_all_commands $1)
    do
        scriptname_to_command "$cmd" "$1"
    done | sort
}

# Argument 1: Caller script name
# Argzment 2: Command name
caller_util_script_for() {
    echo "$(dirname ${BASH_SOURCE[0]})/${1}-${2}.sh"
}

# Argument 1: Caller script name
# Argzment 2: Command name
caller_util_get_script() {
    local SCRIPT=$(caller_util_script_for $1 $2)

    [[ ! -f $SCRIPT ]] && stderr "Not available: $COMMAND -> $SCRIPT" && exit 1
    [[ ! -x $SCRIPT ]] && stderr "Not executeable: $SCRIPT" && exit 1

    echo "$SCRIPT"
}

#
# Container helper functions
#

# get the configuration.nix path for the container by name
container_conf_path() {
    echo /var/lib/containers/$1/etc/nixos/configuration.nix
}

