#!/bin/bash
# Transferir archivelogs del directorio de envío al standby vía rsync sobre SSH

SEND_DIR="/home/oracle/standby/send"
STANDBY_USER="oracle"
STANDBY_HOST="standby.example.com"
STANDBY_PATH="/home/oracle/standby/receive"
SSH_KEY="/home/oracle/.ssh/id_rsa"

mkdir -p "$SEND_DIR"

# Enviar archivos y moverlos a un subdirectorio 'sent' tras la transferencia exitosa
mkdir -p "$SEND_DIR/sent"

rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" --remove-source-files "$SEND_DIR/" "$STANDBY_USER@$STANDBY_HOST:$STANDBY_PATH/"

# Mover cualquier archivo restante (por seguridad) a sent
find "$SEND_DIR" -maxdepth 1 -type f -name '*' -exec mv {} "$SEND_DIR/sent/" \;

exit 0
