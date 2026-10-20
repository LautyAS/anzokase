
#!/bin/bash

source lib/logging.sh
source lib/chroot.sh

install_aur() {

    local repo="$1"
    local target_pkg="${2:-$1}"

    if [[ -z "$repo" ]]; then
        log "Error: no se especificó un repositorio AUR."
        return 1
    fi

    log "Instalando paquete AUR: $target_pkg"

    if ! arch-chroot /mnt /bin/bash -s -- \
        "$USERNAME" "$repo" "$target_pkg" <<'CHROOT'
set -Eeuo pipefail

USERNAME="$1"
repo="$2"
target_pkg="$3"

BUILD_DIR="/home/$USERNAME/$repo"

# ----------------------------------------
# Clonar y construir
# ----------------------------------------

rm -rf -- "$BUILD_DIR"

su - "$USERNAME" -c "
    set -e
    cd /home/$USERNAME
    git clone https://aur.archlinux.org/$repo.git
    cd $repo
    makepkg -sf --noconfirm
"

# ----------------------------------------
# Seleccionar paquete generado
# ----------------------------------------

shopt -s nullglob
pkgfiles=( "$BUILD_DIR"/*.pkg.tar.zst )
selected=()

if (( ${#pkgfiles[@]} == 0 )); then
    echo "ERROR: no se generaron paquetes instalables." >&2
    exit 1
fi

for pkgfile in "${pkgfiles[@]}"; do
    pkgname=$(pacman -Qp --print-format '%n' "$pkgfile")

    if [[ "$pkgname" == "$target_pkg" ]]; then
        selected+=( "$pkgfile" )
    fi
done

if (( ${#selected[@]} == 0 )); then
    echo "ERROR: no se encontró el paquete $target_pkg." >&2
    exit 1
fi

# ----------------------------------------
# Instalar
# ----------------------------------------

pacman -U --noconfirm "${selected[@]}"

# ----------------------------------------
# Cleanup
# ----------------------------------------

rm -rf -- "$BUILD_DIR"

CHROOT
    then
        log "Error instalando paquete AUR: $target_pkg"
        return 1
    fi

    success "$target_pkg instalado correctamente."
}

