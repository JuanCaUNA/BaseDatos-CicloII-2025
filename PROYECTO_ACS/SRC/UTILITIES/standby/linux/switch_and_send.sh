#!/bin/bash
# For: Primary server
# Purpose: Forzar SWITCH LOGFILE y mover los archivelogs nuevos a un directorio de envío
# Editar las variables a continuación para adaptarse al entorno

ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
ORACLE_SID="ORCL"
SQLPLUS="$ORACLE_HOME/bin/sqlplus"
ARCHIVE_DIR="/u01/app/oracle/oradata/${ORACLE_SID}/archivelog"
SEND_DIR="/home/oracle/standby/send"

mkdir -p "$SEND_DIR"

# Forzar switch
export ORACLE_HOME ORACLE_SID
"$SQLPLUS" -s / as sysdba <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
ALTER SYSTEM SWITCH LOGFILE;
EXIT;
EOF

# Mover archivelogs generados recientemente al directorio de envío
# Se asume que los archivos de archivelog están en $ARCHIVE_DIR
find "$ARCHIVE_DIR" -type f -mmin -10 -name '*.arc' -o -name '*.log' | while read -r f; do
  # Evitar mover si ya está en SEND_DIR
  if [[ "$f" != "$SEND_DIR"* ]]; then
    cp -v "$f" "$SEND_DIR/"
  fi
done

exit 0
