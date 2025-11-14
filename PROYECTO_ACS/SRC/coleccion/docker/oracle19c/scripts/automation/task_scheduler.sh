#!/bin/bash
set -euo pipefail

# Inicia tareas recurrentes según el rol de la instancia (primary o standby).
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

WAIT_SCRIPT="/opt/oracle/scripts/common/wait-for-service.sh"
require_command "$WAIT_SCRIPT"
require_command nohup

STANDBY_STATUS_FILE="${STATE_ROOT}/init_standby.status"

ensure_service_ready() {
  log_info "Esperando disponibilidad del servicio ${1}."
  bash "$WAIT_SCRIPT" --service "$1" --host localhost --port 1521 --timeout 900 --method lsnrctl
}

wait_standby_ready() {
  local timeout=${STANDBY_READY_TIMEOUT:-900}
  local waited=0
  local step=10
  if [[ ! -f "$STANDBY_STATUS_FILE" ]]; then
    log_info "Esperando confirmación de standby (${STANDBY_STATUS_FILE})."
  fi
  while (( waited < timeout )); do
    if [[ -f "$STANDBY_STATUS_FILE" ]]; then
      if grep -q 'OK' "$STANDBY_STATUS_FILE" 2>/dev/null; then
        log_success "Standby reporta estado OK (archivo ${STANDBY_STATUS_FILE})."
        return 0
      fi
    fi
    sleep "$step"
    (( waited += step ))
  done
  log_warn "No se detectó estado OK del standby tras ${timeout}s; se continuará de todos modos."
  return 1
}

start_daemon() {
  local name="$1"
  shift
  local pid_file="${STATE_ROOT}/${name}.pid"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid=$(cat "$pid_file")
    if kill -0 "$pid" >/dev/null 2>&1; then
      log_info "Daemon ${name} ya se encuentra en ejecución (pid=${pid})."
      return 0
    fi
  fi
  log_info "Lanzando daemon ${name}."
  mkdir -p "$LOG_ROOT"
  nohup "$@" >>"${LOG_ROOT}/${name}.log" 2>&1 &
  echo $! > "$pid_file"
}

case "$ORACLE_SID" in
  ORCL)
    ensure_service_ready "ORCL"
    wait_standby_ready || true
    start_daemon "archivelog_transfer" /opt/oracle/scripts/automation/archivelog_transfer.sh --daemon
    start_daemon "backup_transfer" /opt/oracle/scripts/automation/backup_transfer.sh --daemon
    log_success "Daemons de primary activos."
    ;;
  STBY)
    ensure_service_ready "STBY"
    start_daemon "archivelog_purge" /opt/oracle/scripts/automation/archivelog_purge.sh --daemon
    log_success "Daemons de standby activos."
    ;;
  *)
    log_warn "ORACLE_SID=${ORACLE_SID} no reconocido para scheduler automático."
    ;;
 esac

exit 0
