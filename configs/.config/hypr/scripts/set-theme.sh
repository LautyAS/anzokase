#!/bin/bash

THEME=$1
HYPR="$HOME/.config/hypr"
QS="$HOME/.config/quickshell"
KITTY="$HOME/.config/kitty"

if [[ "$THEME" != "dark" && "$THEME" != "light" ]]; then
    echo "Usage: set-theme.sh dark|light"
    exit 1
fi

# ---------------- Hyprland ----------------
ln -sf "$HYPR/themes/$THEME.conf" "$HYPR/modules/theme.conf"

# ---------------- GTK ----------------
if [ "$THEME" = "dark" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme Kimi-dark
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
else
    gsettings set org.gnome.desktop.interface gtk-theme Kimi
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
fi

# ---------------- QT / Kvantum ----------------
qt6ct_conf="$HOME/.config/qt6ct/qt6ct.conf"
kv_conf="$HOME/.config/Kvantum/kvantum.kvconfig"

mkdir -p ~/.config/qt6ct
mkdir -p ~/.config/Kvantum

if [ "$THEME" = "dark" ]; then
    KV_THEME="KvGnomeDark"
else
    KV_THEME="KvGnome"
fi

# Configurar qt6ct
cat > "$qt6ct_conf" <<EOF
[Appearance]
style=kvantum
icon_theme=Papirus
EOF

# Configurar Kvantum (sin abrir GUI)
cat > "$kv_conf" <<EOF
[General]
theme=$KV_THEME
EOF

# ---------------- Kitty ----------------
ln -sf "$KITTY/themes/$THEME.conf" "$KITTY/themes/current.conf"
pkill -USR1 kitty

# ---------------- Quickshell ----------------
ln -sf "$QS/colors/$THEME.json" "$QS/colors/current.json"
echo "$THEME" > "$QS/colors/.current_mode"

# ---------------- Reload Hyprland ----------------
hyprctl reload

# ---------------- Restart Quickshell ----------------
pkill qs
setsid qs >/dev/null 2>&1 &

notify-send "Theme" "Switched to $THEME theme"
