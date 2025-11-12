#!/bin/bash
set -euo pipefail

# Genera un backup RMAN en el directorio compartido para facilitar su réplica.
# Ejecutar en oracle_primary. Permite nivel incremental (0 o 1) y etiquetas personalizadas.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

BACKUP_LEVEL=${BACKUP_LEVEL:-0}
INCLUDE_ARCH=${INCLUDE_ARCH:-true}
KEEP_DAYS=${KEEP_DAYS:-7}
TAG_PREFIX=${TAG_PREFIX:-ACS_DG}
LOG_FILE="${LOG_ROOT}/backup_transfer.log"
TARGET_ROOT="/opt/oracle/shared/backups"
MODE="once"
CHECK_INTERVAL=${CHECK_INTERVAL:-86400}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --level)
      BACKUP_LEVEL="$2"
      shift 2
      ;;
    --tag)
  TAG_PREFIX="$2"
  shift 2
      ;;
    --keep-days)
      KEEP_DAYS="$2"
      shift 2
      ;;
    --no-archivelogs)
      INCLUDE_ARCH="false"
      shift
      ;;
    --daemon)
      MODE="daemon"
      shift
      ;;
    --interval)
      CHECK_INTERVAL="$2"
      shift 2
      ;;
    --once)
      MODE="once"
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Uso: backup_transfer.sh [opciones]
  --level <0|1>        Nivel incremental RMAN (0 por defecto)
  --tag <prefijo>      Prefijo de tag para identificar el backup (ACS_DG por defecto)
  --keep-days <n>      Días a conservar backups locales (7 por defecto)
  --no-archivelogs     Omite backup de archivelogs
  --daemon             Ejecuta el backup diariamente (usar junto a --interval)
  --interval <s>       Intervalo entre backups en modo daemon (86400s por defecto)
EOF
      exit 0
      ;;
    *)
      log_error "Parámetro desconocido: $1"
      exit 2
      ;;
  esac
done

mkdir -p "$TARGET_ROOT" "$LOG_ROOT"
touch "$LOG_FILE"
chmod 750 "$TARGET_ROOT" 2>/dev/null || true
chmod 640 "$LOG_FILE" 2>/dev/null || true
exec >>"$LOG_FILE" 2>&1
require_command rman
require_command find

run_backup() {
  local tmp
  local timestamp
  timestamp=$(date '+%Y%m%d_%H%M%S')
  local tag="${TAG_PREFIX}_L${BACKUP_LEVEL}_${timestamp}"
  local output_dir="${TARGET_ROOT}/${timestamp}"
  mkdir -p "$output_dir"
  tmp=$(mktemp)
  local rman_cmd
  rman_cmd=$(mktemp)
  log_info "Iniciando backup RMAN (nivel ${BACKUP_LEVEL}, tag ${tag})."
  {
    echo "RUN {"
    echo "  CROSSCHECK ARCHIVELOG ALL;"
    echo "  CROSSCHECK BACKUP;"
    echo "  DELETE NOPROMPT OBSOLETE RECOVERY WINDOW OF ${KEEP_DAYS} DAYS;"
    echo "  BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL ${BACKUP_LEVEL}" \
      "    FORMAT '${output_dir}/%d_L${BACKUP_LEVEL}_%U.bkp'" \
      "    TAG '${tag}'" \
         "    DATABASE;"
    echo "  BACKUP CURRENT CONTROLFILE TAG '${tag}_CTL'" \
      "    FORMAT '${output_dir}/%d_CTL_%U.bkp';"
    if [[ "${INCLUDE_ARCH,,}" == "true" ]]; then
   echo "  BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL NOT BACKED UP TAG '${tag}_ARCH'" \
     "    FORMAT '${output_dir}/%d_ARCH_%U.bkp';"
    fi
    echo "}"
    echo "EXIT;"
  } > "$rman_cmd"

  rman target "sys/${ORACLE_PWD:-admin123}@${ORACLE_SID}" cmdfile="$rman_cmd" log="$tmp"
  local status=$?
  cat "$tmp" >> "$LOG_FILE"
  rm -f "$tmp" "$rman_cmd"
  if (( status != 0 )); then
    log_error "Backup RMAN finalizó con código ${status}."
    return "$status"
  fi
  log_success "Backup finalizado. Archivos en ${output_dir}."
  find "$TARGET_ROOT" -maxdepth 1 -mindepth 1 -type d -mtime +"${KEEP_DAYS}" -print -exec rm -rf {} \;
  return 0
}

if [[ "$MODE" == "once" ]]; then
  run_backup
  exit $?
fi

while true; do
  run_backup || log_error "Backup en ejecución programada falló."
  sleep "$CHECK_INTERVAL"
done
