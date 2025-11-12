#!/bin/bash
set -euo pipefail

# Garantiza que el listener del standby esté configurado y activo.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-STBY}
source /opt/oracle/scripts/common/lib.sh

SERVICE_NAME=${SERVICE_NAME:-$ORACLE_SID}
LISTENER_NAME=${LISTENER_NAME:-LISTENER}
PORT=${LISTENER_PORT:-1521}
LISTENER_DIR="${ORACLE_HOME}/network/admin"
LISTENER_FILE="${LISTENER_DIR}/listener.ora"
TEMPLATE="/opt/oracle/config/listener.ora"
LSNRCTL="${ORACLE_HOME}/bin/lsnrctl"
WAIT_SCRIPT="/opt/oracle/scripts/common/wait-for-service.sh"

require_command "$LSNRCTL"
require_command "$WAIT_SCRIPT"

mkdir -p "$LISTENER_DIR"

normalize() {
  tr '\n' ' ' < "$1" | tr -s ' '
}

needs_update=true
if [[ -f "$LISTENER_FILE" ]]; then
  normalized=$(normalize "$LISTENER_FILE")
  if [[ "$normalized" =~ SID_NAME[[:space:]]*=[[:space:]]*${ORACLE_SID} ]] && \
     [[ "$normalized" =~ GLOBAL_DBNAME[[:space:]]*=[[:space:]]*${SERVICE_NAME} ]]; then
    needs_update=false
  fi
fi

if [[ "$needs_update" == false ]]; then
  log_info "listener.ora ya contiene la entrada estática para ${ORACLE_SID}."
  exit 0
fi

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

if [[ -f "$TEMPLATE" ]]; then
  cat "$TEMPLATE" > "$tmp_file"
  printf '\n' >> "$tmp_file"
else
  cat <<EOF > "$tmp_file"
# listener.ora generado automáticamente para soporte de Data Guard
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1))
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = ${PORT}))
    )
  )

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
EOF
fi

cat <<EOF >> "$tmp_file"

# Entrada estática requerida para la instancia ${ORACLE_SID}
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${SERVICE_NAME})
      (ORACLE_HOME = ${ORACLE_HOME})
      (SID_NAME = ${ORACLE_SID})
    )
    (SID_DESC =
      (GLOBAL_DBNAME = ${SERVICE_NAME}_DGMGRL)
      (ORACLE_HOME = ${ORACLE_HOME})
      (SID_NAME = ${ORACLE_SID})
    )
  )
EOF

if [[ -f "$LISTENER_FILE" ]] && cmp -s "$tmp_file" "$LISTENER_FILE"; then
  log_info "listener.ora ya se encuentra actualizado."
  exit 0
fi

mv "$tmp_file" "$LISTENER_FILE"
trap - EXIT
chown oracle:oinstall "$LISTENER_FILE" 2>/dev/null || true
chmod 640 "$LISTENER_FILE" 2>/dev/null || true

if "$LSNRCTL" status "$LISTENER_NAME" >/dev/null 2>&1; then
  if "$LSNRCTL" reload "$LISTENER_NAME" >/dev/null 2>&1; then
    log_info "listener ${LISTENER_NAME} recargado tras actualización."
  else
    log_warn "reload falló, intentando reinicio completo."
    "$LSNRCTL" stop "$LISTENER_NAME" >/dev/null 2>&1 || true
    "$LSNRCTL" start "$LISTENER_NAME"
  fi
else
  log_info "listener ${LISTENER_NAME} no estaba activo, iniciándolo."
  "$LSNRCTL" start "$LISTENER_NAME"
fi

# Esperar a que el listener publique el servicio
sleep 2
bash "$WAIT_SCRIPT" --host "localhost" --port "$PORT" --service "$SERVICE_NAME" --timeout 60 --method lsnrctl

log_success "Listener ${LISTENER_NAME} operativo."
