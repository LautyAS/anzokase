#!/bin/bash
set -e

# ============================================
# Anzokase - 03 System Configuration
# ============================================

source lib/logging.sh
source lib/utils.sh
source lib/chroot.sh
source lib/services.sh
source lib/bootloader.sh
source lib/security.sh
source lib/makepkg.sh
source lib/aur.sh

CONFIG_FILE="/mnt/anzokase/install.conf"

log "=== Anzokase - System Configuration ==="

require_root

# --------------------------------------------
# Verificar config
# --------------------------------------------

if [[ ! -f "$CONFIG_FILE" ]]; then
    error "No se encontró $CONFIG_FILE"

    exit 1
fi

# --------------------------------------------
# Copiar config temporalmente al host
# --------------------------------------------

cp "$CONFIG_FILE" /tmp/anzokase.conf

source /tmp/anzokase.conf

# --------------------------------------------
# Pacman configuration
# --------------------------------------------

log "Configurando pacman..."

PACMAN_CONF="/mnt/etc/pacman.conf"

cp "$PACMAN_CONF" "${PACMAN_CONF}.bak"

sed -i 's/^#Color/Color/' "$PACMAN_CONF"

grep -q "^ILoveCandy" "$PACMAN_CONF" || \
    sed -i '/#VerbosePkgLists/a ILoveCandy' "$PACMAN_CONF"

sed -i \
    's/^#ParallelDownloads.*/ParallelDownloads = 10/' \
    "$PACMAN_CONF"

# Multilib
sed -i '/^\s*#\[multilib\]/s/^#//' "$PACMAN_CONF"

sed -i \
    '/^\[multilib\]/,/^$/s/^\s*#//' \
    "$PACMAN_CONF"

# --------------------------------------------
# Chroot configuration
# --------------------------------------------

log "Entrando al chroot..."

arch-chroot /mnt /bin/bash <<EOF
set -e

source /anzokase/install.conf

# ============================================
# Locale
# ============================================

echo "$LOCALE UTF-8" >> /etc/locale.gen

locale-gen

echo "LANG=$LOCALE" > /etc/locale.conf

# ============================================
# Timezone
# ============================================

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

hwclock --systohc

# ============================================
# Hostname
# ============================================

echo "$HOSTNAME" > /etc/hostname

cat > /etc/hosts <<HOSTS
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS

# ============================================
# User
# ============================================

useradd -m -G wheel -s /bin/bash "$USERNAME"

echo "$USERNAME:$PASSWORD" | chpasswd

echo "root:$ROOTPASS" | chpasswd

# ============================================
# Sudo
# ============================================

sed -i \
's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' \
/etc/sudoers

# ============================================
# Makepkg optimization
# ============================================

sed -i \
's/-march=x86-64/-march=native/g' \
/etc/makepkg.conf

sed -i \
"s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/" \
/etc/makepkg.conf

# ============================================
# NetworkManager
# ============================================

systemctl enable NetworkManager

# ============================================
# SSD trim
# ============================================

systemctl enable fstrim.timer

EOF

# --------------------------------------------
# Chaotic-AUR
# --------------------------------------------

if [[ "$ENABLE_CHAOTIC" == "true" ]]; then

    log "Configurando Chaotic-AUR..."

    arch_chroot_run "
        pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    "

    arch_chroot_run "
        pacman-key --lsign-key 3056513887B78AEB
    "

    arch_chroot_run "
        pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    "

    arch_chroot_run "
        pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    "

    cat >> /mnt/etc/pacman.conf <<CHAOTIC

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist

CHAOTIC

fi

# --------------------------------------------
# Repositories update
# --------------------------------------------

arch_chroot_run "
    pacman -Syu --noconfirm
"

# --------------------------------------------
# ZRAM
# --------------------------------------------

if [[ "$ENABLE_ZRAM" == "true" ]]; then

    log "Instalando ZRAM..."

    arch_chroot_run "
        pacman -S --needed --noconfirm zram-generator
    "

    cat > /mnt/etc/systemd/zram-generator.conf <<ZRAM
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM

fi

# --------------------------------------------
# Firewall
# --------------------------------------------

if [[ "$ENABLE_UFW" == "true" ]]; then

    log "Configurando UFW..."

    arch_chroot_run "
        pacman -S --needed --noconfirm ufw
    "

    arch_chroot_run "
        systemctl enable ufw
    "

fi

# --------------------------------------------
# Laptop packages/services
# --------------------------------------------

if [[ "$IS_LAPTOP" == "true" ]]; then

    log "Configurando optimizaciones para laptop..."

    arch_chroot_run "
        pacman -S --needed --noconfirm \
        tlp \
        thermald \
        acpi \
        power-profiles-daemon \
        upower
    "

    arch_chroot_run "
        systemctl enable tlp
    "

    arch_chroot_run "
        systemctl enable power-profiles-daemon
    "

fi

# --------------------------------------------
# os-prober
# --------------------------------------------

if [[ "$ENABLE_OS_PROBER" == "true" ]]; then

    log "Habilitando os-prober..."

    echo 'GRUB_DISABLE_OS_PROBER=false' \
        >> /mnt/etc/default/grub

fi

# --------------------------------------------
# GRUB
# --------------------------------------------

log "Instalando GRUB..."

arch-chroot /mnt /bin/bash <<EOF
set -e

grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot/efi \
    --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg

EOF

# --------------------------------------------
# Paru
# --------------------------------------------

log "Instalando paru..."

arch-chroot /mnt /bin/bash <<EOF
set -e

pacman -S rust cargo --noconfirm --needed

su - "$USERNAME" -c "
    git clone https://aur.archlinux.org/paru.git

    cd paru

    makepkg -si --noconfirm
"

rm -rf /home/$USERNAME/paru

EOF

# --------------------------------------------
# Final
# --------------------------------------------

success "Configuración del sistema completada."

echo
echo "Próximo paso:"
echo "  stages/04-desktop.sh"
echo
