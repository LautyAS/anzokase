#!/bin/bash

AVAILABLE_KERNELS=(
    linux
    linux-lts
    linux-zen
    linux-cachyos
)

kernel_headers() {
    case "$1" in
        linux)
            echo "linux-headers"
            ;;
        linux-lts)
            echo "linux-lts-headers"
            ;;
        linux-zen)
            echo "linux-zen-headers"
            ;;
        linux-cachyos)
            echo "linux-cachyos-headers"
            ;;
    esac
}
