#!/bin/bash
set -euo pipefail

# Asegura que exista el password file requerido por Data Guard en el primary.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

ORACLE_PWD=${ORACLE_PWD:-admin123}
PWFILE="${ORACLE_HOME}/dbs/orapw${ORACLE_SID}"
ORAPWD_BIN="${ORACLE_HOME}/bin/orapwd"

require_command "$ORAPWD_BIN"

if [[ -f "$PWFILE" ]]; then
  log_info "Password file ${PWFILE} ya existe."
  exit 0
fi

umask 077
"$ORAPWD_BIN" FILE="$PWFILE" FORCE=Y FORMAT=12 PASSWORD="$ORACLE_PWD" ENTRIES=30
chown oracle:oinstall "$PWFILE" 2>/dev/null || true
chmod 600 "$PWFILE" 2>/dev/null || true

log_success "Password file ${PWFILE} listo."
