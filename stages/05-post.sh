#!/bin/bash
set -e

# ============================================
# Anzokase - 05 Post Installation
# ============================================

source lib/logging.sh
source lib/utils.sh
source lib/chroot.sh

CONFIG_FILE="/mnt/anzokase/install.conf"

log "=== Anzokase - Post Installation ==="

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
# Crear directorios usuario
# --------------------------------------------

log "Creando estructura de directorios..."

arch-chroot /mnt /bin/bash <<EOF
set -e

su - "$USERNAME" -c "

mkdir -p ~/Downloads
mkdir -p ~/Documents
mkdir -p ~/Pictures
mkdir -p ~/Videos
mkdir -p ~/Music
mkdir -p ~/Projects
mkdir -p ~/.config

"

EOF

# --------------------------------------------
# Permisos sudo wheel
# --------------------------------------------

log "Verificando sudo..."

arch_chroot_run "
    sed -i \
    's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' \
    /etc/sudoers
"

# --------------------------------------------
# Configuración mkinitcpio
# --------------------------------------------

log "Configurando mkinitcpio..."

arch_chroot_run "
    mkinitcpio -P
"

# --------------------------------------------
# NVIDIA DRM modeset
# --------------------------------------------

if [[ "$GPU_VENDOR" == "NVIDIA" ]]; then

    log "Habilitando DRM modeset para NVIDIA..."

    sed -i \
    's/^GRUB_CMDLINE_LINUX_DEFAULT=\"/&nvidia_drm.modeset=1 /' \
    /mnt/etc/default/grub

    arch_chroot_run "
        grub-mkconfig -o /boot/grub/grub.cfg
    "

fi

# --------------------------------------------
# SSD optimizations
# --------------------------------------------

log "Aplicando optimizaciones SSD..."

cat > /mnt/etc/sysctl.d/99-anzokase.conf <<EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF

# --------------------------------------------
# systemd-oomd
# --------------------------------------------

log "Habilitando systemd-oomd..."

arch_chroot_run "
    systemctl enable systemd-oomd
"

# --------------------------------------------
# PipeWire realtime
# --------------------------------------------

log "Configurando PipeWire realtime..."

cat > /mnt/etc/security/limits.d/99-realtime.conf <<EOF
@audio   -  rtprio     95
@audio   -  memlock    unlimited
EOF

# --------------------------------------------
# Limpiar huérfanos
# --------------------------------------------

log "Limpiando paquetes huérfanos..."

arch-chroot /mnt /bin/bash <<EOF
set -e

orphans=\$(pacman -Qtdq || true)

if [[ -n "\$orphans" ]]; then
    pacman -Rns --noconfirm \$orphans
fi

EOF

# --------------------------------------------
# Limpiar cache pacman
# --------------------------------------------

log "Limpiando cache de pacman..."

arch_chroot_run "
    pacman -Scc --noconfirm
"

# --------------------------------------------
# Ownership configs
# --------------------------------------------

log "Corrigiendo ownership..."

arch_chroot_run "
    chown -R $USERNAME:$USERNAME /home/$USERNAME
"

# --------------------------------------------
# Mensaje MOTD
# --------------------------------------------

log "Configurando MOTD..."

cat > /mnt/etc/motd <<EOF

=========================================
        Welcome to Anzokase
=========================================

Arch Linux + Hyprland
Minimal, modular and optimized.

EOF

# --------------------------------------------
# Información final
# --------------------------------------------

success "Post-install completado."

echo
echo "Próximo paso:"
echo "  stages/06-rice.sh"
echo
