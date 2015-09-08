#!/usr/env bash

NIX_SCRIPT_COMMANDS=$(cat <<EOS
channel
container
diff-generations
download-sources
ls-profiles
show-commit
show-generation
switch
update-package-def

EOS
)

_nix-script() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--conf= --list-commands -l -v -d -h $NIX_SCRIPT_COMMANDS"

    if [[ -z "$cur" || $(echo $opts | grep $cur) ]] ; then
        [[ $(echo $NIX_SCRIPT_COMMANDS | grep $prev) ]] && return 1
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
}
complete -F _nix-script nix-script

