#!/bin/bash

source lib/logging.sh
source lib/chroot.sh

install_aur() {

    local package="$1"

    log "Instalando paquete AUR: $package"

    arch-chroot /mnt /bin/bash <<EOF
set -e

cd /home/$USERNAME

# ----------------------------------------
# Clonar
# ----------------------------------------

rm -rf "$package"

su - "$USERNAME" -c "

cd /home/$USERNAME && \
git clone https://aur.archlinux.org/$package.git && \
cd $package && \
makepkg -sf --noconfirm
"

# ----------------------------------------
# Instalar paquetes generados
# ----------------------------------------

cd /home/$USERNAME/$package

for pkgfile in *.pkg.tar.zst; do

    pacman -U --noconfirm "\$pkgfile"

done

# ----------------------------------------
# Cleanup
# ----------------------------------------

cd /home/$USERNAME

rm -rf "$package"

EOF

    success "$package instalado correctamente."
}
