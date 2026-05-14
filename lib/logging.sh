#!/bin/bash

log() {
    printf "\n[ \033[1;34mINFO\033[0m ] %s\n" "$1"
}

warn() {
    printf "\n[ \033[1;33mWARN\033[0m ] %s\n" "$1"
}

error() {
    printf "\n[ \033[1;31mERROR\033[0m ] %s\n" "$1"
}

success() {
    printf "\n[ \033[1;32mOK\033[0m ] %s\n" "$1"
}
