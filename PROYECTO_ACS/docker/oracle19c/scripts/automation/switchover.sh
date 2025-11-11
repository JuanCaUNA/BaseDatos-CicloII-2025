#!/bin/bash
set -euo pipefail

# Ejecuta un switchover manual validando condiciones previas y posteriores.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

PRIMARY_ALIAS=${PRIMARY_ALIAS:-ORCL}
STANDBY_ALIAS=${STANDBY_ALIAS:-STBY}
ORACLE_PWD=${ORACLE_PWD:-admin123}
RETRY_DELAY=${RETRY_DELAY:-120}
MAX_RETRIES=${MAX_RETRIES:-2}
AUTO_CONFIRM=false
LOG_FILE="${LOG_ROOT}/switchover.log"

declare -a CLEANUP_CMDS

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-confirm)
      AUTO_CONFIRM=true
      shift
      ;;
    --retries)
      MAX_RETRIES="$2"
      shift 2
      ;;
    --delay)
      RETRY_DELAY="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Uso: switchover.sh [opciones]
  --auto-confirm   No solicita confirmación interactiva
  --retries <n>    Número de reintentos en caso de fallo (2 por defecto)
  --delay <seg>    Segundos de espera entre reintentos (120 por defecto)
EOF
      exit 0
      ;;
    *)
      log_error "Parámetro desconocido: $1"
      exit 2
      ;;
  esac
done

mkdir -p "$LOG_ROOT"
touch "$LOG_FILE"
chmod 640 "$LOG_FILE" 2>/dev/null || true
exec >>"$LOG_FILE" 2>&1

require_command sqlplus

sql_run() {
  local alias="$1"
  local statement="$2"
  sqlplus -s "sys/${ORACLE_PWD}@${alias} as sysdba" <<SQL
SET FEEDBACK OFF
SET HEADING OFF
SET PAGESIZE 0
WHENEVER SQLERROR EXIT SQL.SQLCODE
${statement}
EXIT;
SQL
}

check_primary_ready() {
  local status role open_mode
  read -r status <<<"$(sql_run "$PRIMARY_ALIAS" "SELECT switchover_status FROM v\$database;")"
  read -r role <<<"$(sql_run "$PRIMARY_ALIAS" "SELECT database_role FROM v\$database;")"
  read -r open_mode <<<"$(sql_run "$PRIMARY_ALIAS" "SELECT open_mode FROM v\$database;")"
  log_info "PRIMARY ${PRIMARY_ALIAS} -> role=${role} open=${open_mode} switchover_status=${status}"
  if [[ "$role" != "PRIMARY" ]]; then
    log_error "Instancia ${PRIMARY_ALIAS} no está en rol PRIMARY."
    return 1
  fi
  local normalized_status
  normalized_status=${status// /_}
  case "$normalized_status" in
    TO_STANDBY|SESSIONS_ACTIVE)
      return 0
      ;;
    *)
      log_error "Switchover_status actual (${status}) no permite switchover."
      return 1
      ;;
  esac
}

check_standby_ready() {
  local role mrp
  read -r role <<<"$(sql_run "$STANDBY_ALIAS" "SELECT database_role FROM v\$database;")"
  log_info "STANDBY ${STANDBY_ALIAS} -> role=${role}"
  if [[ "$role" != "PHYSICAL STANDBY" ]]; then
    log_error "Instancia ${STANDBY_ALIAS} no está en rol PHYSICAL STANDBY."
    return 1
  fi
  mrp=$(sql_run "$STANDBY_ALIAS" "SELECT COUNT(*) FROM v\$managed_standby WHERE process LIKE 'MRP%';")
  if [[ "$mrp" -eq 0 ]]; then
    log_warn "MRP no se encuentra activo en ${STANDBY_ALIAS}."
  fi
  return 0
}

precheck() {
  check_primary_ready
  check_standby_ready
}

activate_mrp() {
  sql_run "$1" "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;" || {
    log_warn "No se pudo activar MRP automáticamente en $1."
    return 1
  }
  log_success "MRP activado en $1."
}

switchover_once() {
  log_info "Cancelando MRP en ${STANDBY_ALIAS}."
  sql_run "$STANDBY_ALIAS" "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;" || true

  log_info "Finalizando apply pendiente en ${STANDBY_ALIAS}."
  if ! sql_run "$STANDBY_ALIAS" "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;"; then
    log_error "No se pudo finalizar la recuperación en ${STANDBY_ALIAS}."
    return 1
  fi

  log_info "Ejecutando switchover en ${PRIMARY_ALIAS}."
  sql_run "$PRIMARY_ALIAS" "ALTER DATABASE COMMIT TO SWITCHOVER TO PHYSICAL STANDBY WITH SESSION SHUTDOWN;"

  log_info "Abriendo nuevo primary (${STANDBY_ALIAS})."
  sql_run "$STANDBY_ALIAS" "ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY;" || return 1
  sql_run "$STANDBY_ALIAS" "ALTER DATABASE OPEN;"

  log_info "Reiniciando instancia en ${PRIMARY_ALIAS} como standby."
  sql_run "$PRIMARY_ALIAS" "SHUTDOWN IMMEDIATE;" || true
  sql_run "$PRIMARY_ALIAS" "STARTUP MOUNT;"
  activate_mrp "$PRIMARY_ALIAS"

  log_success "Switchover completado."
}

postcheck() {
  local role_primary role_standby
  role_primary=$(sql_run "$STANDBY_ALIAS" "SELECT database_role FROM v\$database;")
  role_standby=$(sql_run "$PRIMARY_ALIAS" "SELECT database_role FROM v\$database;")
  log_info "Roles actuales -> ${STANDBY_ALIAS}: ${role_primary}, ${PRIMARY_ALIAS}: ${role_standby}."
  if [[ "$role_primary" != "PRIMARY" || "$role_standby" != "PHYSICAL STANDBY" ]]; then
    log_error "Roles inesperados tras switchover."
    return 1
  fi
  activate_mrp "$PRIMARY_ALIAS"
  return 0
}

if ! $AUTO_CONFIRM; then
  read -r -p "¿Confirmar switchover de ${PRIMARY_ALIAS} a ${STANDBY_ALIAS}? (yes/NO): " resp
  if [[ "$resp" != "yes" ]]; then
    log_warn "Switchover cancelado por el operador."
    exit 0
  fi
fi

precheck

attempt=1
until (( attempt > MAX_RETRIES )); do
  if switchover_once; then
    if postcheck; then
      exit 0
    fi
  fi
  log_warn "Intento ${attempt}/${MAX_RETRIES} de switchover falló."
  if (( attempt == MAX_RETRIES )); then
    log_error "Switchover abortado tras ${MAX_RETRIES} intentos."
    exit 1
  fi
  log_info "Esperando ${RETRY_DELAY}s antes de reintentar."
  sleep "$RETRY_DELAY"
  ((attempt++))
  precheck || true
 done
