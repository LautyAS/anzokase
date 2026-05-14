#!/bin/bash
set -e

# ============================================
# Anzokase - 06 Rice / User Config
# ============================================

source lib/logging.sh
source lib/utils.sh
source lib/chroot.sh

CONFIG_FILE="/mnt/anzokase/install.conf"

log "=== Anzokase - Rice Installation ==="

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
# Verificar configs/
# --------------------------------------------

if [[ ! -d "configs" ]]; then
    error "No se encontró la carpeta configs/"

    exit 1
fi

# --------------------------------------------
# Copiar configuración
# --------------------------------------------

log "Copiando configuración de usuario..."

cp -r configs/. "/mnt/home/$USERNAME/"

# --------------------------------------------
# Ownership
# --------------------------------------------

log "Aplicando ownership..."

arch_chroot_run "
    chown -R $USERNAME:$USERNAME /home/$USERNAME
"

# --------------------------------------------
# Permisos básicos
# --------------------------------------------

log "Aplicando permisos..."

find "/mnt/home/$USERNAME" -type d -exec chmod 755 {} \;

find "/mnt/home/$USERNAME" -type f -exec chmod 644 {} \;

# Scripts ejecutables típicos
find "/mnt/home/$USERNAME/.config" \
    -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \;

# --------------------------------------------
# Limpiar archivos basura
# --------------------------------------------

log "Limpiando archivos temporales..."

find "/mnt/home/$USERNAME" \
    -name ".DS_Store" \
    -delete

find "/mnt/home/$USERNAME" \
    -name "Thumbs.db" \
    -delete

# --------------------------------------------
# Shell default
# --------------------------------------------

log "Configurando shell default..."

arch_chroot_run "
    chsh -s /bin/bash $USERNAME
"

# --------------------------------------------
# Final
# --------------------------------------------

success "Rice aplicado correctamente."

echo
echo "========================================="
echo "        Anzokase instalado"
echo "========================================="
echo
echo "Podés reiniciar el sistema."
echo
echo "Algunas recomendaciones:"
echo
echo "  • Verificar mirrors"
echo "  • Actualizar firmware con fwupd"
echo "  • Revisar snapshots si usás BTRFS"
echo
echo "Comando recomendado:"
echo
echo "  fwupdmgr get-updates"
echo
