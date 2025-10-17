#!/bin/bash
# Purga archivelogs locales mayores a 3 días (rm y RMAN delete)

ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
ORACLE_SID="ORCL"
RMAN="$ORACLE_HOME/bin/rman"
ARCHIVE_DIR="/u01/app/oracle/oradata/${ORACLE_SID}/archivelog"

export ORACLE_HOME ORACLE_SID

# RMAN delete for safety
${RMAN} target / <<EOF
DELETE NOPROMPT ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-3';
EXIT
EOF

# Remove files older than 3 days from archive dir (fail-safe)
find "$ARCHIVE_DIR" -type f -mtime +3 -exec rm -v {} \;

exit 0
