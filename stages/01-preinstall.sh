#!/bin/bash
set -e

# ============================================
# Anzokase - 01 Preinstall
# ============================================

source lib/logging.sh
source lib/ui.sh
source lib/utils.sh
source lib/hardware.sh
source lib/gpu.sh
source lib/disks.sh
source lib/kernels.sh

CONFIG_FILE="config/install.conf"

log "=== Anzokase - Preinstall ==="

require_root

# --------------------------------------------
# Dependencias básicas
# --------------------------------------------

log "Instalando dependencias necesarias..."

pacman -Sy --noconfirm

pacman -S --needed --noconfirm \
    fzf \
    reflector \
    git

# --------------------------------------------
# Selección de disco
# --------------------------------------------

log "Detectando discos disponibles..."

DISK=$(
    list_disks | fzf \
        --height=10 \
        --border \
        --prompt="Seleccioná el disco destino → " \
        | awk '{print $1}'
)

if [[ -z "$DISK" ]]; then
    error "No se seleccionó ningún disco."
    exit 1
fi

success "Disco seleccionado: $DISK"

# --------------------------------------------
# Hostname
# --------------------------------------------

read -rp "Hostname: " HOSTNAME

# --------------------------------------------
# Usuario
# --------------------------------------------

read -rp "Usuario: " USERNAME

# --------------------------------------------
# Password usuario
# --------------------------------------------

while true; do
    read -rsp "Password usuario: " PASSWORD
    echo

    read -rsp "Confirmar password: " PASSWORD2
    echo

    [[ "$PASSWORD" == "$PASSWORD2" ]] && break

    warn "Las contraseñas no coinciden."
done

# --------------------------------------------
# Password root
# --------------------------------------------

if confirm "¿Usar la misma contraseña para root?"; then
    ROOTPASS="$PASSWORD"
else
    while true; do
        read -rsp "Password root: " ROOTPASS
        echo

        read -rsp "Confirmar password root: " ROOTPASS2
        echo

        [[ "$ROOTPASS" == "$ROOTPASS2" ]] && break

        warn "Las contraseñas no coinciden."
    done
fi

# --------------------------------------------
# Timezone
# --------------------------------------------

log "Seleccionar zona horaria..."

TIMEZONE=$(
    find /usr/share/zoneinfo -type f \
    | sed 's|/usr/share/zoneinfo/||' \
    | fzf \
        --height=20 \
        --border \
        --prompt="Timezone → "
)

# --------------------------------------------
# Locale
# --------------------------------------------

LOCALE=$(select_option \
    "Locale" \
    "es_AR.UTF-8" \
    "es_ES.UTF-8" \
    "en_US.UTF-8"
)

# --------------------------------------------
# Filesystem
# --------------------------------------------

FILESYSTEM=$(select_option \
    "Filesystem" \
    "ext4" \
    "btrfs"
)

# --------------------------------------------
# Kernels
# --------------------------------------------

log "Seleccioná uno o más kernels..."

KERNEL_SELECTION=$(
    printf "%s\n" "${AVAILABLE_KERNELS[@]}" | \
    fzf \
        --multi \
        --height=10 \
        --border \
        --prompt="Kernels → "
)

if [[ -z "$KERNEL_SELECTION" ]]; then
    error "Debés seleccionar al menos un kernel."
    exit 1
fi

mapfile -t KERNELS <<< "$KERNEL_SELECTION"

# --------------------------------------------
# Kernel default
# --------------------------------------------

DEFAULT_KERNEL=$(printf "%s\n" "${KERNELS[@]}" | fzf \
    --height=10 \
    --border \
    --prompt="Kernel default → "
)

# --------------------------------------------
# CPU / microcode
# --------------------------------------------

CPU_VENDOR=$(detect_cpu_vendor)
MICROCODE=$(detect_microcode)

success "CPU detectada: $CPU_VENDOR"
success "Microcode: $MICROCODE"

# --------------------------------------------
# GPU
# --------------------------------------------

GPU_VENDOR=$(get_gpu_vendor)

success "GPU detectada: $GPU_VENDOR"

# --------------------------------------------
# Laptop detection
# --------------------------------------------

if is_laptop; then
    IS_LAPTOP=true
    success "Laptop detectada."
else
    IS_LAPTOP=false
    success "Desktop detectado."
fi

# --------------------------------------------
# Bluetooth
# --------------------------------------------

if has_bluetooth; then
    BLUETOOTH_AVAILABLE=true

    if confirm "Bluetooth detectado. ¿Habilitar soporte Bluetooth?"; then
        ENABLE_BLUETOOTH=true
    else
        ENABLE_BLUETOOTH=false
    fi
else
    BLUETOOTH_AVAILABLE=false
    ENABLE_BLUETOOTH=false
fi

# --------------------------------------------
# Chaotic-AUR
# --------------------------------------------

ENABLE_CHAOTIC=false

for kernel in "${KERNELS[@]}"; do
    if [[ "$kernel" == "linux-cachyos" ]]; then
        ENABLE_CHAOTIC=true
    fi
done

if [[ "$ENABLE_CHAOTIC" != true ]]; then

    if confirm "¿Habilitar Chaotic-AUR?"; then
        ENABLE_CHAOTIC=true
    fi

fi

# --------------------------------------------
# ZRAM
# --------------------------------------------

if confirm "¿Habilitar ZRAM?"; then
    ENABLE_ZRAM=true
else
    ENABLE_ZRAM=false
fi

# --------------------------------------------
# Dualboot / os-prober
# --------------------------------------------

if confirm "¿Habilitar soporte dualboot con os-prober?"; then
    ENABLE_OS_PROBER=true
else
    ENABLE_OS_PROBER=false
fi

# --------------------------------------------
# Gaming packages
# --------------------------------------------

if confirm "¿Instalar paquetes gaming?"; then
    ENABLE_GAMING=true
else
    ENABLE_GAMING=false
fi

# --------------------------------------------
# Printing
# --------------------------------------------

if confirm "¿Instalar soporte de impresión?"; then
    ENABLE_PRINTING=true
else
    ENABLE_PRINTING=false
fi

# --------------------------------------------
# Flatpak
# --------------------------------------------

if confirm "¿Instalar soporte Flatpak?"; then
    ENABLE_FLATPAK=true
else
    ENABLE_FLATPAK=false
fi

# --------------------------------------------
# Seguridad
# --------------------------------------------

if confirm "¿Habilitar firewall UFW?"; then
    ENABLE_UFW=true
else
    ENABLE_UFW=false
fi

# --------------------------------------------
# Confirmación final
# --------------------------------------------

log "Resumen de instalación"

echo "Disco:              $DISK"
echo "Hostname:           $HOSTNAME"
echo "Usuario:            $USERNAME"
echo "Filesystem:         $FILESYSTEM"
echo "Timezone:           $TIMEZONE"
echo "Locale:             $LOCALE"
echo "GPU:                $GPU_VENDOR"
echo "CPU:                $CPU_VENDOR"
echo "Laptop:             $IS_LAPTOP"
echo "Chaotic-AUR:        $ENABLE_CHAOTIC"
echo "Bluetooth:          $ENABLE_BLUETOOTH"
echo "ZRAM:               $ENABLE_ZRAM"
echo "Gaming:             $ENABLE_GAMING"
echo "Printing:           $ENABLE_PRINTING"
echo "Flatpak:            $ENABLE_FLATPAK"
echo "Firewall:           $ENABLE_UFW"
echo "Dualboot:           $ENABLE_OS_PROBER"

echo
echo "Kernels seleccionados:"
printf ' - %s\n' "${KERNELS[@]}"

echo
echo "Kernel default: $DEFAULT_KERNEL"

echo

if ! confirm "¿Continuar con la instalación?"; then
    warn "Instalación cancelada."
    exit 0
fi

# --------------------------------------------
# Crear directorio config
# --------------------------------------------

mkdir -p config

# --------------------------------------------
# Guardar configuración
# --------------------------------------------

log "Guardando configuración..."

cat > "$CONFIG_FILE" <<EOF
DISK="$DISK"

HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"

PASSWORD="$PASSWORD"
ROOTPASS="$ROOTPASS"

TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"

FILESYSTEM="$FILESYSTEM"

CPU_VENDOR="$CPU_VENDOR"
MICROCODE="$MICROCODE"

GPU_VENDOR="$GPU_VENDOR"

IS_LAPTOP="$IS_LAPTOP"

ENABLE_BLUETOOTH="$ENABLE_BLUETOOTH"
ENABLE_CHAOTIC="$ENABLE_CHAOTIC"
ENABLE_ZRAM="$ENABLE_ZRAM"
ENABLE_GAMING="$ENABLE_GAMING"
ENABLE_PRINTING="$ENABLE_PRINTING"
ENABLE_FLATPAK="$ENABLE_FLATPAK"
ENABLE_UFW="$ENABLE_UFW"
ENABLE_OS_PROBER="$ENABLE_OS_PROBER"

DEFAULT_KERNEL="$DEFAULT_KERNEL"

KERNELS=(
$(printf '"%s"\n' "${KERNELS[@]}")
)
EOF

success "Configuración guardada en $CONFIG_FILE"

log "Preinstall completado."
log "Continuá con stages/02-base.sh"
