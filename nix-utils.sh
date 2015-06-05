#!/usr/bin/env bash

Color_Off='\e[0m'
Red='\e[0;31m'
Green='\e[0;32m'

stderr() {
    echo -e "${Red}[$(basename $0)]: ${*}${Color_Off}" >&2
}

stdout() {
    [ $VERBOSE -eq 1 ] && echo -e "${Green}[$(basename $0)]:${Color_Off} $*"
}

