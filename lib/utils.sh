#!/bin/bash

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ejecutarse como root."
        exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ensure_directory() {
    mkdir -p "$1"
}

save_config() {
    cat > config/install.conf <<EOF
$1
EOF
}
