#!/bin/bash
set -euo pipefail

# Fuerza la transferencia periódica de archivelogs desde el primary hacia el standby.
# Ejecutar en oracle_primary. Puede operar en modo daemon (--daemon) o a demanda (--once).
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

MAX_BYTES=${MAX_BYTES:-52428800}         # 50 MB
MAX_WAIT=${MAX_WAIT:-300}                # 5 minutos
CHECK_INTERVAL=${CHECK_INTERVAL:-60}
ARCHIVE_RETRY_ATTEMPTS=${ARCHIVE_RETRY_ATTEMPTS:-5}
ARCHIVE_RETRY_DELAY=${ARCHIVE_RETRY_DELAY:-30}
ARCHIVE_DEST_CHECK_INTERVAL=${ARCHIVE_DEST_CHECK_INTERVAL:-300}
STATE_FILE="${STATE_ROOT}/archivelog_transfer.state"
LOG_FILE="${LOG_ROOT}/archivelog_transfer.log"
MODE="daemon"
ARCHIVE_DIR=""
LAST_DEST_CHECK=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --once)
      MODE="once"
      shift
      ;;
    --daemon)
      MODE="daemon"
      shift
      ;;
    --max-bytes)
      MAX_BYTES="$2"
      shift 2
      ;;
    --max-wait)
      MAX_WAIT="$2"
      shift 2
      ;;
    --interval)
      CHECK_INTERVAL="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Uso: archivelog_transfer.sh [--once|--daemon] [opciones]
  --max-bytes <bytes>   Requiere transferencia tras generar este volumen (50MB por defecto)
  --max-wait <seg>      Requiere transferencia tras este tiempo (300s por defecto)
  --interval <seg>      Intervalo de verificación en modo daemon (60s por defecto)
EOF
      exit 0
      ;;
    *)
      log_error "Parámetro desconocido: $1"
      exit 2
      ;;
  esac
done

mkdir -p "$(dirname "$STATE_FILE")"
touch "$LOG_FILE"
chmod 640 "$LOG_FILE" 2>/dev/null || true
exec >>"$LOG_FILE" 2>&1

log_info "Iniciando control de transferencia de archivelogs (modo ${MODE})."

LAST_SEQ=0
LAST_TS=0

trim_value() {
  local raw="$1"
  echo "${raw//[[:space:]]/}"
}

trim_number() {
  trim_value "$1"
}

if [[ -f "$STATE_FILE" ]]; then
  if ! source "$STATE_FILE" 2>/dev/null; then
    log_warn "Estado previo ilegible, se reiniciará el seguimiento."
    LAST_SEQ=0
    LAST_TS=0
  fi
fi
LAST_SEQ=$(trim_number "${LAST_SEQ:-0}")
LAST_TS=$(trim_number "${LAST_TS:-0}")

save_state() {
  local tmp
  tmp=$(mktemp)
  {
    printf 'LAST_SEQ=%s\n' "$(trim_number "$LAST_SEQ")"
    printf 'LAST_TS=%s\n' "$(trim_number "$LAST_TS")"
  } > "$tmp"
  mv "$tmp" "$STATE_FILE"
  chmod 640 "$STATE_FILE" 2>/dev/null || true
}

query_stats() {
  local last_seq="$1"
  sqlplus -s / as sysdba <<SQL
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET VERIFY OFF
SELECT NVL(MAX(sequence#),0) FROM v\$archived_log WHERE dest_id = 1;
SELECT NVL(SUM(blocks*block_size),0) FROM v\$archived_log WHERE dest_id = 1 AND sequence# > ${last_seq};
SELECT value FROM v\$parameter WHERE name = 'log_archive_dest_state_2';
SELECT NVL(status,'UNKNOWN') FROM v\$archive_dest WHERE dest_id = 2;
SELECT NVL(error,'-') FROM v\$archive_dest WHERE dest_id = 2;
EXIT;
SQL
}

discover_archive_dir() {
  local raw
  if ! raw=$(sqlplus -s / as sysdba <<'SQL'
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SELECT REGEXP_SUBSTR(value, 'LOCATION=([^ ,]+)', 1, 1, NULL, 1)
  FROM v$parameter
 WHERE name = 'log_archive_dest_1';
EXIT;
SQL
  ); then
    log_warn "No se pudo consultar log_archive_dest_1."
    ARCHIVE_DIR=""
    return
  fi
  ARCHIVE_DIR=$(trim_value "${raw:-}")
  if [[ -n "$ARCHIVE_DIR" ]]; then
    log_info "Destino local de archivelogs: ${ARCHIVE_DIR}."
  else
    log_warn "No se pudo determinar LOCATION de log_archive_dest_1; pruebas de escritura omitidas."
  fi
}

verify_archive_dir() {
  local now testfile
  if [[ -z "$ARCHIVE_DIR" ]]; then
    return 0
  fi
  now=$(date +%s)
  if (( now - LAST_DEST_CHECK < ARCHIVE_DEST_CHECK_INTERVAL )); then
    return 0
  fi
  LAST_DEST_CHECK=$now
  if [[ ! -d "$ARCHIVE_DIR" ]]; then
    log_error "Directorio ${ARCHIVE_DIR} no existe (log_archive_dest_1)."
    return 1
  fi
  if [[ ! -w "$ARCHIVE_DIR" ]]; then
    log_error "Directorio ${ARCHIVE_DIR} no es escribible (log_archive_dest_1)."
    return 1
  fi
  if ! testfile=$(mktemp "${ARCHIVE_DIR}/.archivelog_transfer_test.XXXXXX" 2>/dev/null); then
    log_error "No se pudo crear archivo de prueba en ${ARCHIVE_DIR}."
    return 1
  fi
  rm -f "$testfile"
  return 0
}

recover_dest2() {
  local status="$1"
  local error_message="$2"
  if [[ "$status" != "ERROR" ]]; then
    return 0
  fi
  log_warn "log_archive_dest_2 en estado ERROR (${error_message:-sin detalle}); se reiniciará."
  if sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2 = DEFER;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2 = ENABLE;
EXIT;
SQL
  then
    log_info "log_archive_dest_2 restablecido."
    return 0
  fi
  log_error "No se pudo restablecer log_archive_dest_2 (continuará en ERROR)."
  return 1
}

force_transfer_once() {
  sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2 = ENABLE;
ALTER SYSTEM ARCHIVE LOG CURRENT;
EXIT;
SQL
}

force_transfer() {
  log_info "Forzando transferencia de archivelogs al standby."
  if retry_command "$ARCHIVE_RETRY_ATTEMPTS" "$ARCHIVE_RETRY_DELAY" force_transfer_once; then
    return 0
  fi
  return 1
}

run_cycle() {
  local now lines dest_state dest_status dest_error current_seq bytes elapsed prev_seq post_lines new_seq new_bytes
  now=$(date +%s)

  if ! mapfile -t lines < <(query_stats "$LAST_SEQ"); then
    log_error "No fue posible consultar métricas de archivelog."
    return 2
  fi

  current_seq=$(trim_number "${lines[0]:-0}")
  bytes=$(trim_number "${lines[1]:-0}")
  dest_state=$(echo "${lines[2]:-UNKNOWN}" | tr -d '[:space:]')
  dest_status=$(echo "${lines[3]:-UNKNOWN}" | tr -d '[:space:]')
  dest_error=$(trim_value "${lines[4]:--}")

  if [[ "$dest_state" != "enable" && "$dest_state" != "ENABLE" ]]; then
    log_warn "log_archive_dest_state_2=${dest_state}, se habilitará."
    if ! sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2 = ENABLE;
EXIT;
SQL
    then
      log_error "No se pudo habilitar log_archive_dest_state_2."
      return 2
    fi
  fi

  recover_dest2 "$dest_status" "$dest_error"

  if ! verify_archive_dir; then
    log_warn "Prueba de escritura en destino local falló; se reintentará."
    return 2
  fi

  elapsed=$(( now - LAST_TS ))
  if (( elapsed < 0 )); then
    elapsed=0
  fi

  trigger_transfer() {
    prev_seq=$LAST_SEQ
    if ! force_transfer; then
      log_warn "Intento de transferencia fallido."
      return 1
    fi
    if ! mapfile -t post_lines < <(query_stats "$prev_seq"); then
      log_error "No fue posible actualizar métricas tras la transferencia."
      return 1
    fi
    new_seq=$(trim_number "${post_lines[0]:-0}")
    new_bytes=$(trim_number "${post_lines[1]:-0}")
    if (( new_seq <= prev_seq )); then
      log_warn "Transferencia completada sin nueva secuencia (previa=${prev_seq})."
    fi
    LAST_SEQ=$new_seq
    LAST_TS=$(date +%s)
    save_state
    return 0
  }

  if (( current_seq > LAST_SEQ )) && (( bytes >= MAX_BYTES )); then
    if trigger_transfer; then
      log_success "Transferencia ejecutada (volumen ${bytes} bytes, seq ${LAST_SEQ})."
      return 0
    fi
    return 1
  fi

  if (( elapsed >= MAX_WAIT )); then
    if trigger_transfer; then
      log_success "Transferencia ejecutada por temporizador (elapsed ${elapsed}s, seq ${LAST_SEQ}, bytes ${new_bytes:-0})."
      return 0
    fi
    return 1
  fi

  log_info "Sin acciones: secuencia=${LAST_SEQ}, bytes_acumulados=${bytes}, elapsed=${elapsed}s."
  return 1
}


discover_archive_dir

if [[ "$MODE" == "once" ]]; then
  run_cycle
  exit 0
fi

while true; do
  run_cycle || true
  sleep "$CHECK_INTERVAL"
done
