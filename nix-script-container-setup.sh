#!/usr/bin/env

source $(dirname ${BASH_SOURCE[0]})/nix-utils.sh

usage() {
    cat <<EOS >&2
    $(help_synopsis "container" "setup [-h] -n <container name> [-e] [-d <dir>] [-t <template>]")

    -n <name>     | Container name
    -e            | Do not edit the configuration.nix of the container
    -t <template> | Use this configuration template
    -d <dir>      | Use this configuration template dir, default: $RC_CONTAINER_CONF_TEMPLATE_DIR
    -h            | Show this help and exit

$(help_end)
EOS
}

DO_EDIT=0 # 0 == true
TEMPLATE=
TEMPLATE_DIR=$RC_CONTAINER_CONF_TEMPLATE_DIR

while getopts "n:et:d:h" OPTION
do
    case $OPTION in
        n)
            NAME=$OPTARG
            dbg "NAME = $NAME"
            ;;

        e)
            DO_EDIT=1 # 1 == false
            dbg "DO_NOT_EDIT = $DO_NOT_EDIT"
            ;;

        t)
            TEMPLATE=$OPTARG
            dbg "TEMPLATE = $TEMPLATE"
            ;;

        d)
            TEMPLATE_DIR=$OPTARG
            dbg "TEMPLATE_DIR = $TEMPLATE_DIR"
            ;;

        h)
            usage
            exit 0
            ;;
        *)
            ;;
    esac
done

[[ -z "$NAME" ]] && stderr "No container name given" && exit 1
[[ -z "$TEMPLATE_DIR" && ! -z "$TEMPLATE" ]] && \
    stderr "No container config template dir path given" && exit 1

stdout "Creating container '$NAME'"
explain sudo nixos-container create $NAME
stdout "Creating container '$NAME': done"

if [[ ! -z "$TEMPLATE_DIR" && ! -z "$TEMPLATE" ]]
then
    stdout "Looking for template in template dir"

    __template__="${TEMPLATE_DIR}/${TEMPLATE}.template.nix"
    if [[ -e "$__template__" ]]
    then
        explain sudo cp $__template__ $(container_conf_path $NAME)
    else
        stderr "'$__template__' does not exist. Exiting"
        exit 1
    fi
else
    stderr "No template dir, no template specified."
    stderr "Won't change configuration.nix automatically"
fi

[[ $DO_EDIT ]] && explain sudo $EDITOR $(container_conf_path $NAME)

stdout "Starting container '$NAME'"
explain sudo nixos-container start $NAME
stdout "Starting container '$NAME': done"

