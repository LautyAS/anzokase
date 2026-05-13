#!/bin/bash

enable_ufw() {
    install_chroot_packages ufw
    arch-chroot /mnt ufw enable
}
