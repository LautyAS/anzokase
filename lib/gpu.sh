#!/bin/bash

detect_nvidia_generation() {
    lspci | grep -i nvidia
}

get_gpu_vendor() {
    if lspci | grep -iq nvidia; then
        echo "NVIDIA"
    elif lspci | grep -iq amd; then
        echo "AMD"
    elif lspci | grep -iq intel; then
        echo "Intel"
    else
        echo "Unknown"
    fi
}
