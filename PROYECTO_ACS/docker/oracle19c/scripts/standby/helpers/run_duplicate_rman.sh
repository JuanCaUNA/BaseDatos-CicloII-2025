#!/bin/bash
set -euo pipefail

# Ejecuta RMAN DUPLICATE para construir el standby a partir del primary.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-STBY}
source /opt/oracle/scripts/common/lib.sh

ORACLE_PWD=${ORACLE_PWD:-admin123}
LOGFILE="${LOG_ROOT}/rman_duplicate.log"
PRIMARY_HOST=${PRIMARY_DB_HOST:-oracle-primary}
PRIMARY_PORT=${PRIMARY_DB_PORT:-1521}
LOCAL_HOST=${LOCAL_LISTENER_HOST:-localhost}
LISTENER_PORT=${LISTENER_PORT:-1521}
WAIT_SCRIPT="/opt/oracle/scripts/common/wait-for-service.sh"
MAX_RETRIES=${RMAN_MAX_RETRIES:-3}
RETRY_DELAY=${RMAN_RETRY_DELAY:-120}
CONNECTIVITY_RETRIES=${RMAN_CONNECTIVITY_RETRIES:-6}
CONNECTIVITY_DELAY=${RMAN_CONNECTIVITY_DELAY:-30}
PRIMARY_ALIAS=${PRIMARY_TNS_ALIAS:-ORCL}
STANDBY_ALIAS=${STANDBY_TNS_ALIAS:-${ORACLE_SID}}
PRIMARY_DB_UNIQUE_NAME=${PRIMARY_DB_UNIQUE_NAME:-ORCL}
STANDBY_DB_UNIQUE_NAME=${STANDBY_DB_UNIQUE_NAME:-${ORACLE_SID}}
STATE_FILE="${STATE_ROOT}/standby_duplicate.done"

touch "$LOGFILE"
chmod 640 "$LOGFILE" 2>/dev/null || true

require_command rman
require_command sqlplus
require_command tnsping
require_command "$WAIT_SCRIPT"
require_command find

prepare_standby_directories() {
  local base="/opt/oracle/oradata/${ORACLE_SID}"
  mkdir -p "$base" "$base/ORCLPDB1" "$base/pdbseed" "$base/archive_logs" 2>/dev/null || true
  chmod 750 "$base" 2>/dev/null || true
}

wait_primary_marker() {
  local marker="${STATE_ROOT}/primary_ready.ok"
  local timeout=${PRIMARY_READY_FILE_TIMEOUT:-900}
  local waited=0
  local interval=${PRIMARY_READY_FILE_POLL:-5}

  log_info "Esperando confirmación del primary (${marker})."
  while (( waited < timeout )); do
    if [[ -f "$marker" ]]; then
      log_success "Marcador de primary detectado (${marker})."
      return 0
    fi
    sleep "$interval"
    (( waited += interval ))
  done

  log_error "No se encontró el marcador de finalización del primary (${marker}) tras ${timeout}s."
  return 1
}

run_tnsping() {
  local alias="$1"
  if tnsping "$alias" >/tmp/tnsping.out 2>&1; then
    log_success "tnsping ${alias} exitoso."
    cat /tmp/tnsping.out >> "$LOGFILE"
    rm -f /tmp/tnsping.out
    return 0
  fi
  log_error "tnsping ${alias} falló."
  cat /tmp/tnsping.out >> "$LOGFILE"
  rm -f /tmp/tnsping.out
  return 1
}

wait_service() {
  local host="$1"
  local port="$2"
  local service="$3"
  local alias="${4:-}"
  local args=(--host "$host" --port "$port" --service "$service" --timeout 300)
  if [[ -n "$alias" ]]; then
    args+=(--alias "$alias")
  fi
  bash "$WAIT_SCRIPT" "${args[@]}"
}

test_rman_connectivity() {
  local tmp
  tmp=$(mktemp)
  if rman target "sys/${ORACLE_PWD}@${PRIMARY_ALIAS}" auxiliary "sys/${ORACLE_PWD}@${STANDBY_ALIAS}" log="$tmp" <<<'EXIT'; then
    log_success "Conectividad RMAN verificada (${PRIMARY_ALIAS} -> ${STANDBY_ALIAS})."
    cat "$tmp" >> "$LOGFILE"
    rm -f "$tmp"
    return 0
  fi
  log_error "Conexión RMAN falló, revisar credenciales y red."
  cat "$tmp" >> "$LOGFILE"
  rm -f "$tmp"
  return 1
}

has_datafiles() {
  shopt -s nullglob
  local datafiles=(/opt/oracle/oradata/${ORACLE_SID}/*.dbf)
  shopt -u nullglob
  (( ${#datafiles[@]} > 0 ))
}

cleanup_standby_files() {
  local base="/opt/oracle/oradata/${ORACLE_SID}"
  log_warn "Limpiando datafiles residuales en ${base}."
  if [[ -d "$base" ]]; then
    find "$base" -mindepth 1 -maxdepth 1 ! -name 'dbconfig' -print -exec rm -rf {} \;
  fi
  rm -f "$STATE_FILE"
  prepare_standby_directories
}

wait_primary_ready() {
  local attempts=${PRIMARY_READY_ATTEMPTS:-40}
  local delay=${PRIMARY_READY_DELAY:-15}
  local try=1
  while (( try <= attempts )); do
    local output=""
    if output=$(sqlplus -s "sys/${ORACLE_PWD}@${PRIMARY_ALIAS} as sysdba" <<'SQL'
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT open_mode || ',' || database_role FROM v$database;
EXIT SQL.SQLCODE;
SQL
    ); then
      output=$(echo "$output" | tail -n 1)
      local canonical
      canonical=$(echo "$output" | tr -d ' \r\n')
      canonical=${canonical// /}
      if [[ "$canonical" == 'READWRITE,PRIMARY' ]]; then
        log_success "Primary ${PRIMARY_ALIAS} listo (READ WRITE)."
        return 0
      fi
      log_warn "Primary responde '${output}', se reintentará en ${delay}s."
    else
      log_warn "Consulta a primary falló (intento ${try}/${attempts})."
    fi
    sleep "$delay"
    ((try++))
  done
  log_error "Primary no alcanzó estado READ WRITE tras ${attempts} intentos."
  return 1
}

ensure_managed_recovery() {
  local tmp
  tmp=$(mktemp)
  if sqlplus -s / as sysdba >"$tmp" 2>&1 <<'SQL'
SET FEEDBACK OFF
SET HEADING OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  v_role   v$database.database_role%TYPE;
  v_open   v$database.open_mode%TYPE;
  v_mrp    PLS_INTEGER;
BEGIN
  BEGIN
    SELECT database_role, open_mode INTO v_role, v_open FROM v$database;
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        EXECUTE IMMEDIATE 'ALTER DATABASE MOUNT';
        SELECT database_role, open_mode INTO v_role, v_open FROM v$database;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('STATUS:QUERY_FAILED:' || SQLCODE || ':' || SQLERRM);
          RETURN;
      END;
  END;

  IF v_role <> 'PHYSICAL STANDBY' THEN
    DBMS_OUTPUT.PUT_LINE('STATUS:ROLE_MISMATCH:' || NVL(v_role,'UNKNOWN') || ':' || NVL(v_open,'UNKNOWN'));
    RETURN;
  END IF;

  IF v_open NOT IN ('MOUNTED', 'READ ONLY', 'READ WRITE') THEN
    EXECUTE IMMEDIATE 'ALTER DATABASE MOUNT';
  END IF;

  SELECT COUNT(*) INTO v_mrp FROM v$managed_standby WHERE process LIKE 'MRP%';

  IF v_mrp = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Iniciando Managed Recovery Process...');
    EXECUTE IMMEDIATE 'ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION';
  ELSE
    DBMS_OUTPUT.PUT_LINE('Managed Recovery Process ya se encuentra activo.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('STATUS:SUCCESS');
END;
/
SQL
  then
    cat "$tmp" >> "$LOGFILE"
    if grep -q 'STATUS:SUCCESS' "$tmp"; then
      log_success "Recuperación administrada configurada."
      rm -f "$tmp"
      return 0
    fi
    if grep -q 'STATUS:ROLE_MISMATCH' "$tmp"; then
      log_warn "La base no presenta el rol PHYSICAL STANDBY esperado."
      rm -f "$tmp"
      return 2
    fi
    if grep -q 'STATUS:QUERY_FAILED' "$tmp"; then
      log_error "No fue posible obtener el estado de la base de datos." 
      rm -f "$tmp"
      return 3
    fi
    log_error "Recuperación administrada devolvió un estado desconocido."
    rm -f "$tmp"
    return 1
  fi
  log_error "Fallo al asegurar la recuperación administrada."
  cat "$tmp" >> "$LOGFILE"
  rm -f "$tmp"
  return 1
}

run_duplicate_once() {
  local rman_cmd
  rman_cmd=$(mktemp)
  cat >"$rman_cmd" <<RMAN
CONNECT TARGET sys/${ORACLE_PWD}@ORCL
CONNECT AUXILIARY sys/${ORACLE_PWD}@STBY
RUN {
  DUPLICATE TARGET DATABASE
    FOR STANDBY
    FROM ACTIVE DATABASE
    DORECOVER
    NOFILENAMECHECK;
}
EXIT SQL.SQLCODE;
RMAN

  if rman cmdfile="$rman_cmd" log="$LOGFILE" append; then
    rm -f "$rman_cmd"
    return 0
  fi
  local status=$?
  rm -f "$rman_cmd"
  return "$status"
}

log_info "Esperando listeners y servicios previos a RMAN DUPLICATE."
wait_service "$LOCAL_HOST" "$LISTENER_PORT" "$ORACLE_SID"
wait_service "$PRIMARY_HOST" "$PRIMARY_PORT" "$PRIMARY_ALIAS" "$PRIMARY_ALIAS"

log_info "Validando resolución TNS."
run_tnsping "$PRIMARY_ALIAS" || exit 2
run_tnsping "$STANDBY_ALIAS" || exit 2

wait_primary_marker || exit 4
wait_primary_ready || exit 4

log_info "Verificando conectividad RMAN."
ensure_rman_connectivity() {
  local attempt=1
  while (( attempt <= CONNECTIVITY_RETRIES )); do
    if test_rman_connectivity; then
      return 0
    fi
    if (( attempt == CONNECTIVITY_RETRIES )); then
      break
    fi
    log_warn "Conexión RMAN falló (intento ${attempt}/${CONNECTIVITY_RETRIES}). Reintentando en ${CONNECTIVITY_DELAY}s..."
    sleep "$CONNECTIVITY_DELAY"
    ((attempt++))
  done
  log_error "No fue posible establecer la conexión RMAN tras ${CONNECTIVITY_RETRIES} intentos."
  return 1
}

ensure_rman_connectivity || exit 3

prepare_standby_directories

perform_duplicate() {
  log_info "Iniciando RMAN DUPLICATE (máximo ${MAX_RETRIES} intentos)."
  local attempt=1
  while (( attempt <= MAX_RETRIES )); do
    log_info "Intento ${attempt}/${MAX_RETRIES} de RMAN DUPLICATE."
    if run_duplicate_once; then
      log_success "RMAN DUPLICATE completado con éxito en el intento ${attempt}."
      return 0
    fi
    log_warn "RMAN DUPLICATE falló en el intento ${attempt}."
    if (( attempt == MAX_RETRIES )); then
      log_error "Se alcanzó el máximo de reintentos (${MAX_RETRIES})."
      return 10
    fi
    cleanup_standby_files
    log_info "Reintentando en ${RETRY_DELAY}s..."
    sleep "$RETRY_DELAY"
    ((attempt++))
  done
}

if [[ -f "$STATE_FILE" ]]; then
  log_info "Duplicación previa detectada en ${STATE_FILE}."
else
  if has_datafiles; then
    log_warn "Datafiles existentes sin marca de completado; se eliminarán antes de duplicar."
    cleanup_standby_files
  fi
  if ! perform_duplicate; then
    status=$?
    exit "$status"
  fi
fi

log_info "Verificando Managed Recovery Process."
if ensure_managed_recovery; then
  touch "$STATE_FILE"
  chmod 640 "$STATE_FILE" 2>/dev/null || true
  log_success "Standby listo tras proceso de duplicación."
  exit 0
fi

result=$?
if (( result == 2 )); then
  log_warn "El standby no está en rol físico; se reintentará la duplicación completa."
  cleanup_standby_files
  if ! perform_duplicate; then
    status=$?
    exit "$status"
  fi
  if ensure_managed_recovery; then
    touch "$STATE_FILE"
    chmod 640 "$STATE_FILE" 2>/dev/null || true
    log_success "Standby listo tras reprocesar la duplicación."
    exit 0
  fi
  log_error "La recuperación administrada continúa fallando tras reprocesar la duplicación."
  exit 4
fi

exit "$result"
