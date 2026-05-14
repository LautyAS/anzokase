#!/bin/bash

create_user() {
    local username="$1"
    local password="$2"

    useradd -m -G wheel -s /bin/bash "$username"

    echo "$username:$password" | chpasswd
}
