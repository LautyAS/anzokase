#!/bin/bash

enable_service() {
    systemctl enable "$1"
}

enable_chroot_service() {
    arch-chroot /mnt systemctl enable "$1"
}
