#!/bin/bash
set -e

# ============================================
# Anzokase - 02 Base Installation
# ============================================

source lib/logging.sh
source lib/utils.sh
source lib/disks.sh
source lib/filesystem.sh
source lib/packages.sh
source lib/kernels.sh

CONFIG_FILE="config/install.conf"

log "=== Anzokase - Base Installation ==="

require_root

# --------------------------------------------
# Verificar config
# --------------------------------------------

if [[ ! -f "$CONFIG_FILE" ]]; then
    error "No se encontró $CONFIG_FILE"
    error "Ejecutá primero stages/01-preinstall.sh"

    exit 1
fi

source "$CONFIG_FILE"

# --------------------------------------------
# Confirmación final de disco
# --------------------------------------------

warn "TODOS los datos en $DISK serán eliminados."

read -rp "Continuar? [y/N]: " CONFIRM

case "$CONFIRM" in
    [yY][eE][sS]|[yY]) ;;
    *)
        warn "Instalación cancelada."
        exit 1
        ;;
esac

# --------------------------------------------
# Limpiar mounts previos
# --------------------------------------------

log "Limpiando mounts previos..."

umount -R /mnt 2>/dev/null || true

# --------------------------------------------
# Particionado GPT
# --------------------------------------------

log "Creando tabla GPT..."

parted -s "$DISK" mklabel gpt

# EFI
log "Creando partición EFI..."

parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

# ROOT
log "Creando partición ROOT..."

parted -s "$DISK" mkpart primary 513MiB 100%

# --------------------------------------------
# Detectar nombres de particiones
# --------------------------------------------

PART_SUFFIX=$(detect_partition_suffix "$DISK")

EFI_PART="${DISK}${PART_SUFFIX}1"
ROOT_PART="${DISK}${PART_SUFFIX}2"

success "EFI:  $EFI_PART"
success "ROOT: $ROOT_PART"

# --------------------------------------------
# Formatear EFI
# --------------------------------------------

log "Formateando EFI..."

mkfs.fat -F32 "$EFI_PART"

# --------------------------------------------
# Formatear ROOT según filesystem
# --------------------------------------------

log "Creando filesystem $FILESYSTEM..."

case "$FILESYSTEM" in
    ext4)
        create_ext4_filesystem "$ROOT_PART"
        ;;
    btrfs)
        create_btrfs_filesystem "$ROOT_PART"
        ;;
    *)
        error "Filesystem no soportado: $FILESYSTEM"
        exit 1
        ;;
esac

# --------------------------------------------
# Montaje
# --------------------------------------------

log "Montando particiones..."

mount "$ROOT_PART" /mnt

mkdir -p /mnt/boot/efi

mount "$EFI_PART" /mnt/boot/efi

# --------------------------------------------
# BTRFS subvolumes
# --------------------------------------------

if [[ "$FILESYSTEM" == "btrfs" ]]; then

    log "Configurando subvolúmenes BTRFS..."

    umount /mnt

    mount "$ROOT_PART" /mnt

    btrfs su cr /mnt/@
    btrfs su cr /mnt/@home
    btrfs su cr /mnt/@snapshots
    btrfs su cr /mnt/@cache
    btrfs su cr /mnt/@log

    umount /mnt

    mount -o noatime,compress=zstd,subvol=@ "$ROOT_PART" /mnt

    mkdir -p /mnt/{home,.snapshots,var/cache,var/log}

    mount -o noatime,compress=zstd,subvol=@home \
        "$ROOT_PART" /mnt/home

    mount -o noatime,compress=zstd,subvol=@snapshots \
        "$ROOT_PART" /mnt/.snapshots

    mount -o noatime,compress=zstd,subvol=@cache \
        "$ROOT_PART" /mnt/var/cache

    mount -o noatime,compress=zstd,subvol=@log \
        "$ROOT_PART" /mnt/var/log

    mount "$EFI_PART" /mnt/boot/efi
fi

# --------------------------------------------
# Swapfile
# --------------------------------------------

SWAPFILE_SIZE="4G"

log "Creando swapfile de $SWAPFILE_SIZE..."

fallocate -l "$SWAPFILE_SIZE" /mnt/swapfile

chmod 600 /mnt/swapfile

mkswap /mnt/swapfile

swapon /mnt/swapfile

# --------------------------------------------
# Base packages
# --------------------------------------------

log "Preparando kernels..."

KERNEL_PACKAGES=()

for kernel in "${KERNELS[@]}"; do
    KERNEL_PACKAGES+=("$kernel")
    KERNEL_PACKAGES+=("$(kernel_headers "$kernel")")
done

# --------------------------------------------
# Pacstrap
# --------------------------------------------

log "Instalando sistema base..."

pacstrap /mnt \
    base \
    base-devel \
    linux-firmware \
    neovim \
    sudo \
    networkmanager \
    grub \
    efibootmgr \
    git \
    reflector \
    os-prober \
    "$MICROCODE" \
    "${KERNEL_PACKAGES[@]}"

# --------------------------------------------
# FSTAB
# --------------------------------------------

log "Generando fstab..."

genfstab -U /mnt >> /mnt/etc/fstab

echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

# --------------------------------------------
# Copiar configuración
# --------------------------------------------

log "Copiando configuración..."

mkdir -p /mnt/anzokase

cp "$CONFIG_FILE" /mnt/anzokase/install.conf

# --------------------------------------------
# Información final
# --------------------------------------------

success "Base instalada correctamente."

echo
echo "Sistema montado en /mnt"
echo
echo "Próximo paso:"
echo "  stages/03-system.sh"
echo
