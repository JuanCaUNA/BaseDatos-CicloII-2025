#!/bin/bash
# Ejecuta un backup RMAN diario y transfiere al standby

ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
ORACLE_SID="ORCL"
RMAN="$ORACLE_HOME/bin/rman"
BACKUP_DIR="/u01/backups/${ORACLE_SID}"
STANDBY_USER="oracle"
STANDBY_HOST="standby.example.com"
STANDBY_PATH="/home/oracle/standby/backups"
SSH_KEY="/home/oracle/.ssh/id_rsa"

mkdir -p "$BACKUP_DIR"
export ORACLE_HOME ORACLE_SID

${RMAN} target / <<EOF
RUN {
  CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BACKUP_DIR}/%F';
  BACKUP AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG FORMAT '${BACKUP_DIR}/%d_db_%U';
  DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-3';
}
EXIT
EOF

# Transferir backups al standby
rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" --remove-source-files "$BACKUP_DIR/" "$STANDBY_USER@$STANDBY_HOST:$STANDBY_PATH/"

exit 0
