arch_chroot_run() {
    arch-chroot /mnt /bin/bash -c "$1"
}
