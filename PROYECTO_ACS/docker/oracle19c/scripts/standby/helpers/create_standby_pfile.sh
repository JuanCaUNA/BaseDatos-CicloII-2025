#!/bin/bash
set -euo pipefail

DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-STBY}
source /opt/oracle/scripts/common/lib.sh

TARGET_PFILE="${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora"
TEMP_PFILE="/tmp/init${ORACLE_SID}_temp.ora"

# Generar siempre un PFILE temporal para garantizar parámetros consistentes.
cat <<EOF > "$TEMP_PFILE"
DB_NAME='ORCL'
DB_UNIQUE_NAME='${ORACLE_SID}'
INSTANCE_NAME='${ORACLE_SID}'
SERVICE_NAMES='${ORACLE_SID}'
CONTROL_FILES=('/opt/oracle/oradata/${ORACLE_SID}/control01.ctl','/opt/oracle/oradata/${ORACLE_SID}/control02.ctl')
DB_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/${ORACLE_SID}/'
LOG_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/${ORACLE_SID}/'
AUDIT_FILE_DEST='/opt/oracle/admin/${ORACLE_SID}/adump'
REMOTE_LOGIN_PASSWORDFILE='EXCLUSIVE'
ENABLE_PLUGGABLE_DATABASE=TRUE
EOF

# Copiar al destino (sobrescribe para mantener consistencia).
cp "$TEMP_PFILE" "$TARGET_PFILE"

log_success "Archivo temporal ${TEMP_PFILE} generado."
