#!/bin/bash

create_ext4_filesystem() {
    local partition="$1"

    mkfs.ext4 -F "$partition"
}

create_btrfs_filesystem() {
    local partition="$1"

    mkfs.btrfs -f "$partition"
}
