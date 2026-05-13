#!/bin/bash

select_option() {
    local prompt="$1"
    shift

    printf "%s\n" "$@" | fzf \
        --height=15 \
        --border \
        --prompt="$prompt → "
}

select_multiple() {
    local prompt="$1"
    shift

    printf "%s\n" "$@" | fzf \
        --multi \
        --height=15 \
        --border \
        --prompt="$prompt → "
}

confirm() {
    local prompt="$1"

    read -rp "$prompt [y/N]: " CONFIRM

    case "$CONFIRM" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
