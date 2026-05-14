#!/bin/bash

detect_cpu_vendor() {
    lscpu | awk -F: '/Vendor ID/ {print $2}' | xargs
}

detect_cpu_model() {
    lscpu | awk -F: '/Model name/ {print $2}' | xargs
}

detect_gpu() {
    lspci | grep -E "VGA|3D"
}

is_laptop() {
    ls /sys/class/power_supply/BAT* &>/dev/null
}

has_bluetooth() {
    lsusb | grep -iq bluetooth
}

detect_microcode() {
    local vendor
    vendor=$(detect_cpu_vendor)

    case "$vendor" in
        GenuineIntel)
            echo "intel-ucode"
            ;;
        AuthenticAMD)
            echo "amd-ucode"
            ;;
    esac
}
