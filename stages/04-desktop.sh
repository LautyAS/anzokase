#!/bin/bash
set -e

# ============================================
# Anzokase - 04 Desktop Installation
# ============================================

source lib/logging.sh
source lib/utils.sh
source lib/chroot.sh
source lib/packages.sh
source lib/gpu.sh
source lib/aur.sh

# Package groups
source packages/core.sh
source packages/hyprland.sh
source packages/audio.sh
source packages/fonts.sh
source packages/bluetooth.sh
source packages/gaming.sh
source packages/printing.sh

CONFIG_FILE="/mnt/anzokase/install.conf"

log "=== Anzokase - Desktop Installation ==="

require_root

# --------------------------------------------
# Verificar config
# --------------------------------------------

if [[ ! -f "$CONFIG_FILE" ]]; then
    error "No se encontró $CONFIG_FILE"

    exit 1
fi

source "$CONFIG_FILE"

# --------------------------------------------
# Actualizar mirrors
# --------------------------------------------

log "Actualizando mirrors dentro del sistema..."

arch_chroot_run "
    reflector \
        --latest 20 \
        --protocol https \
        --sort rate \
        --save /etc/pacman.d/mirrorlist
"

# --------------------------------------------
# Actualización completa
# --------------------------------------------

log "Actualizando sistema..."

arch_chroot_run "
    pacman -Syu --noconfirm
"

# --------------------------------------------
# Instalar paquetes base desktop
# --------------------------------------------

log "Instalando paquetes base del escritorio..."

install_chroot_packages \
    "${packages_core[@]}" \
    "${packages_hyprland[@]}" \
    "${packages_audio[@]}" \
    "${packages_fonts[@]}"

# --------------------------------------------
# Bluetooth
# --------------------------------------------

if [[ "$ENABLE_BLUETOOTH" == "true" ]]; then

    log "Instalando soporte Bluetooth..."

    install_chroot_packages \
        "${packages_bluetooth[@]}"

    arch_chroot_run "
        systemctl enable bluetooth
    "

fi

# --------------------------------------------
# Printing
# --------------------------------------------

if [[ "$ENABLE_PRINTING" == "true" ]]; then

    log "Instalando soporte de impresión..."

    install_chroot_packages \
        "${packages_printing[@]}"

    arch_chroot_run "
        systemctl enable cups
    "

fi

# --------------------------------------------
# Flatpak
# --------------------------------------------

if [[ "$ENABLE_FLATPAK" == "true" ]]; then

    log "Instalando Flatpak..."

    install_chroot_packages flatpak

fi

# --------------------------------------------
# Gaming
# --------------------------------------------

if [[ "$ENABLE_GAMING" == "true" ]]; then

    log "Instalando paquetes gaming..."

    install_chroot_packages \
        "${packages_gaming[@]}"

fi

# --------------------------------------------
# Drivers GPU
# --------------------------------------------

log "Instalando drivers GPU..."

case "$GPU_VENDOR" in

    AMD)

        install_chroot_packages \
            vulkan-radeon \
            lib32-vulkan-radeon

        ;;

    Intel)

        install_chroot_packages \
            vulkan-intel \
            intel-media-driver \
            lib32-vulkan-intel

        ;;

    NVIDIA)

        log "Configurando NVIDIA..."

        # TODO:
        # Detectar automáticamente Turing+
        # para usar nvidia-open

        install_chroot_packages \
            nvidia-dkms \
            nvidia-utils \
            nvidia-settings \
            lib32-nvidia-utils

        ;;

esac

# --------------------------------------------
# Fuentes AUR
# --------------------------------------------

log "Instalando fuentes adicionales..."

arch-chroot /mnt /bin/bash <<EOF
set -e

su - "$USERNAME" -c "

    paru -S --needed --noconfirm \
        maplemono-nf-unhinted
"

EOF

# --------------------------------------------
# Floorp
# --------------------------------------------

log "Instalando Floorp..."

arch-chroot /mnt /bin/bash <<EOF
set -e

su - "$USERNAME" -c "

    paru -S --needed --noconfirm \
        floorp-bin
"

EOF

# --------------------------------------------
# Servicios
# --------------------------------------------

log "Habilitando servicios..."

arch_chroot_run "
    systemctl enable NetworkManager
"

arch_chroot_run "
    systemctl enable ly@tty1.service
"

# --------------------------------------------
# Directorios XDG
# --------------------------------------------

log "Generando directorios XDG..."

arch-chroot /mnt /bin/bash <<EOF
set -e

su - "$USERNAME" -c "
    xdg-user-dirs-update
"

EOF

# --------------------------------------------
# Final
# --------------------------------------------

success "Desktop instalado correctamente."

echo
echo "Próximo paso:"
echo "  stages/05-post.sh"
echo
