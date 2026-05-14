#!/bin/bash

optimize_makepkg() {
    local conf="/etc/makepkg.conf"

    sed -i 's/-march=x86-64/-march=native/g' "$conf"
    sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/" "$conf"
}
