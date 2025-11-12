#!/bin/bash
# Utility helpers shared by the ACS Data Guard automation scripts.
# - Ensures Oracle environment variables are exported
# - Provides minimal logging helpers and retry support
# - Creates default directories for logs and state files when missing

# Export mandatory Oracle variables when the caller did not set them.
export ORACLE_BASE="${ORACLE_BASE:-/opt/oracle}"
export ORACLE_HOME="${ORACLE_HOME:-${ORACLE_BASE}/product/19c/dbhome_1}"
# shellcheck disable=SC2034 # Keep DEFAULT_ORACLE_SID readable for callers
DEFAULT_ORACLE_SID="${DEFAULT_ORACLE_SID:-${ORACLE_SID:-ORCL}}"
export ORACLE_SID="${ORACLE_SID:-${DEFAULT_ORACLE_SID}}"
export PATH="${ORACLE_HOME}/bin:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"
export TNS_ADMIN="${TNS_ADMIN:-${ORACLE_HOME}/network/admin}"
export NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.AL32UTF8}"
umask 027

LOG_ROOT="${LOG_ROOT:-/opt/oracle/shared/logs}"
STATE_ROOT="${STATE_ROOT:-/opt/oracle/shared/state}"
mkdir -p "$LOG_ROOT" "$STATE_ROOT"
chmod 750 "$LOG_ROOT" "$STATE_ROOT" 2>/dev/null || true

# Provide light-weight ANSI color support when running on TTY.
if [[ -t 1 ]]; then
  _ACS_COLOR_INFO='\033[36m'
  _ACS_COLOR_WARN='\033[33m'
  _ACS_COLOR_ERROR='\033[31m'
  _ACS_COLOR_SUCCESS='\033[32m'
  _ACS_COLOR_RESET='\033[0m'
else
  _ACS_COLOR_INFO=''
  _ACS_COLOR_WARN=''
  _ACS_COLOR_ERROR=''
  _ACS_COLOR_SUCCESS=''
  _ACS_COLOR_RESET=''
fi

acs_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
  printf '%b[%s] [INFO] %s%b\n' "${_ACS_COLOR_INFO}" "$(acs_timestamp)" "$*" "${_ACS_COLOR_RESET}"
}

log_warn() {
  printf '%b[%s] [WARN] %s%b\n' "${_ACS_COLOR_WARN}" "$(acs_timestamp)" "$*" "${_ACS_COLOR_RESET}" >&2
}

log_error() {
  printf '%b[%s] [ERROR] %s%b\n' "${_ACS_COLOR_ERROR}" "$(acs_timestamp)" "$*" "${_ACS_COLOR_RESET}" >&2
}

log_success() {
  printf '%b[%s] [OK] %s%b\n' "${_ACS_COLOR_SUCCESS}" "$(acs_timestamp)" "$*" "${_ACS_COLOR_RESET}"
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "Comando requerido no disponible: ${cmd}"
    exit 127
  fi
}

retry_command() {
  local attempts=$1
  local delay=$2
  shift 2
  local try=1
  until "$@"; do
    local status=$?
    if (( try >= attempts )); then
      log_error "Comando \"$*\" falló tras ${attempts} intentos (código ${status})."
      return "$status"
    fi
    log_warn "Intento ${try} de ${attempts} fallido para \"$*\". Reintentando en ${delay}s..."
    sleep "$delay"
    ((try++))
  done
}

run_sqlplus() {
  local connect="/ as sysdba"
  local sql_input=""
  local spool_file=""
  local heading=OFF
  local feedback=OFF
  local pause=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --connect)
        connect="$2"
        shift 2
        ;;
      --sql)
        sql_input="$2"
        shift 2
        ;;
      --file)
        sql_input="$(cat "$2")"
        shift 2
        ;;
      --spool)
        spool_file="$2"
        shift 2
        ;;
      --heading-on)
        heading=ON
        shift
        ;;
      --feedback-on)
        feedback=ON
        shift
        ;;
      --sleep)
        pause="$2"
        shift 2
        ;;
      *)
        log_error "Parámetro desconocido para run_sqlplus: $1"
        return 2
        ;;
    esac
  done

  if [[ -z "$sql_input" ]]; then
    log_error "run_sqlplus requiere SQL via --sql o --file."
    return 2
  fi

  local sql_cmd
  sql_cmd=$(cat <<EOF
SET TERMOUT ON
SET PAGESIZE 200
SET LINESIZE 200
SET SERVEROUTPUT ON
SET HEADING ${heading}
SET FEEDBACK ${feedback}
WHENEVER SQLERROR EXIT SQL.SQLCODE
${spool_file:+SPOOL ${spool_file}}
${sql_input}
${spool_file:+SPOOL OFF}
EXIT
EOF
  )

  sqlplus -s "$connect" <<SQLEOF
${sql_cmd}
SQLEOF
  local status=$?
  if (( pause > 0 )); then
    sleep "$pause"
  fi
  return "$status"
}

wait_for_seconds() {
  local seconds="$1"
  log_info "Esperando ${seconds}s para sincronización."
  sleep "$seconds"
}
