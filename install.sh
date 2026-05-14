#!/bin/bash
set -e

source lib/logging.sh

log "Iniciando Anzokase..."

bash stages/01-preinstall.sh
bash stages/02-base.sh
bash stages/03-system.sh
bash stages/04-desktop.sh
bash stages/05-post.sh
bash stages/06-rice.sh

log "Instalación finalizada."
