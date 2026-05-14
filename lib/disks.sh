#!/bin/bash

list_disks() {
    lsblk -dpno NAME,SIZE | grep -E "/dev/sd|/dev/nvme"
}

detect_partition_suffix() {
    local disk="$1"

    if [[ "$disk" =~ [0-9]$ ]]; then
        echo "p"
    else
        echo ""
    fi
}
