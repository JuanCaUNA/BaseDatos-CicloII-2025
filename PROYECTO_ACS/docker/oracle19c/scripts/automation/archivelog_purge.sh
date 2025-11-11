#!/bin/bash
set -euo pipefail

# Elimina archivelogs aplicados en el standby con más de PURGE_DAYS días.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-STBY}
source /opt/oracle/scripts/common/lib.sh

PURGE_DAYS=${PURGE_DAYS:-3}
CHECK_INTERVAL=${CHECK_INTERVAL:-3600}
MODE="once"
LOG_FILE="${LOG_ROOT}/archivelog_purge.log"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --daemon)
      MODE="daemon"
      shift
      ;;
    --once)
      MODE="once"
      shift
      ;;
    --days)
      PURGE_DAYS="$2"
      shift 2
      ;;
    --interval)
      CHECK_INTERVAL="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Uso: archivelog_purge.sh [--once|--daemon] [opciones]
  --days <n>       Purga archivelogs aplicados con más de n días (3 por defecto)
  --interval <s>   Intervalo entre ejecuciones en modo daemon (3600s por defecto)
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

log_info "Iniciando purga de archivelogs (modo ${MODE}, dias=${PURGE_DAYS})."

purge_once() {
  mapfile -t files < <(sqlplus -s / as sysdba <<SQL
SET HEADING OFF
SET FEEDBACK OFF
SET PAGESIZE 0
SET VERIFY OFF
SELECT name
  FROM v\$archived_log
 WHERE name IS NOT NULL
   AND applied = 'YES'
   AND completion_time < SYSDATE - ${PURGE_DAYS};
EXIT;
SQL
)

  if (( ${#files[@]} == 0 )); then
    log_info "No hay archivelogs elegibles para purga."
    return 0
  fi

  local removed=0
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      rm -f "$file"
      log_info "Archivo purgado: $file"
      ((removed++))
    else
      log_warn "Archivo listado no existe: $file"
    fi
  done
  log_success "Purga completada. Archivos eliminados: ${removed}."
}

if [[ "$MODE" == "once" ]]; then
  purge_once
  exit 0
fi

while true; do
  purge_once || true
  sleep "$CHECK_INTERVAL"
done
