#!/bin/bash

install_paru() {
    local user="$1"

    arch-chroot /mnt su - "$user" -c "
        git clone https://aur.archlinux.org/paru-bin.git &&
        cd paru-bin &&
        makepkg -si --noconfirm
    "
}
