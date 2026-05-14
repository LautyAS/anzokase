#!/bin/bash

install_packages() {
    pacman -S --needed --noconfirm "$@"
}

install_chroot_packages() {
    arch-chroot /mnt pacman -S --needed --noconfirm "$@"
}
