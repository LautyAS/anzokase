#!/bin/bash

install_grub() {
    pacman -S --noconfirm grub efibootmgr os-prober

    grub-install \
        --target=x86_64-efi \
        --efi-directory=/boot/efi \
        --bootloader-id=GRUB

    grub-mkconfig -o /boot/grub/grub.cfg
}
