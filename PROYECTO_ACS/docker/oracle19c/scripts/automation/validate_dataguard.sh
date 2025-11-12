#!/bin/bash
set -euo pipefail

# Valida el estado general de la configuración Data Guard (primary + standby).
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

PRIMARY_ALIAS=${PRIMARY_ALIAS:-ORCL}
STANDBY_ALIAS=${STANDBY_ALIAS:-STBY}
ORACLE_PWD=${ORACLE_PWD:-admin123}
LOG_FILE="${LOG_ROOT}/validate_dataguard.log"
mkdir -p "$LOG_ROOT"
touch "$LOG_FILE"
chmod 640 "$LOG_FILE" 2>/dev/null || true
exec >>"$LOG_FILE" 2>&1

require_command sqlplus
require_command tnsping

trim() {
  echo "$1" | tr -d ' \r\n\t'
}

sql_value() {
  local alias="$1"
  local stmt="$2"
  sqlplus -s "sys/${ORACLE_PWD}@${alias} as sysdba" <<SQL | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 0
${stmt}
EXIT;
SQL
}

check_listener() {
  local alias="$1"
  if tnsping "$alias" >/tmp/tnsping_vdg.out 2>&1; then
    log_success "tnsping ${alias} OK."
    cat /tmp/tnsping_vdg.out >> "$LOG_FILE"
    rm -f /tmp/tnsping_vdg.out
    return 0
  fi
  log_error "tnsping ${alias} falló."
  cat /tmp/tnsping_vdg.out >> "$LOG_FILE"
  rm -f /tmp/tnsping_vdg.out
  return 1
}

STATUS=0

log_info "Validando listeners."
check_listener "$PRIMARY_ALIAS" || STATUS=1
check_listener "$STANDBY_ALIAS" || STATUS=1

log_info "Consultando métricas en primary (${PRIMARY_ALIAS})."
primary_role=$(sql_value "$PRIMARY_ALIAS" "SELECT database_role FROM v\$database;")
primary_mode=$(sql_value "$PRIMARY_ALIAS" "SELECT open_mode FROM v\$database;")
primary_switch=$(sql_value "$PRIMARY_ALIAS" "SELECT switchover_status FROM v\$database;")
primary_seq=$(sql_value "$PRIMARY_ALIAS" "SELECT NVL(MAX(sequence#),0) FROM v\$archived_log WHERE dest_id = 1;")
primary_log_count=$(sql_value "$PRIMARY_ALIAS" "SELECT COUNT(*) FROM v\$log;")
primary_srl_count=$(sql_value "$PRIMARY_ALIAS" "SELECT COUNT(*) FROM v\$standby_log;")
primary_log_max=$(sql_value "$PRIMARY_ALIAS" "SELECT NVL(MAX(bytes),0) FROM v\$log;")
primary_srl_min=$(sql_value "$PRIMARY_ALIAS" "SELECT CASE WHEN COUNT(*) = 0 THEN 0 ELSE NVL(MIN(bytes),0) END FROM v\$standby_log;")
log_info "PRIMARY role=${primary_role} open=${primary_mode} switchover_status=${primary_switch} sequence=${primary_seq}."
if [[ "$primary_role" != "PRIMARY" ]]; then
  log_error "El alias ${PRIMARY_ALIAS} no está en rol PRIMARY."
  STATUS=1
fi

primary_log_count=${primary_log_count:-0}
primary_srl_count=${primary_srl_count:-0}
primary_log_max=${primary_log_max:-0}
primary_srl_min=${primary_srl_min:-0}

log_info "PRIMARY redo groups=${primary_log_count} (max=${primary_log_max} bytes) standby_redo=${primary_srl_count} (min=${primary_srl_min} bytes)."

if (( primary_srl_count < primary_log_count + 1 )); then
  log_error "Standby redo logs insuficientes en el primary: ${primary_srl_count} < ${primary_log_count}+1."
  STATUS=1
fi

if (( primary_srl_min < primary_log_max )); then
  log_error "Standby redo logs más pequeños (${primary_srl_min} bytes) que el redo online (${primary_log_max} bytes)."
  STATUS=1
fi

log_info "Consultando métricas en standby (${STANDBY_ALIAS})."
standby_role=$(sql_value "$STANDBY_ALIAS" "SELECT database_role FROM v\$database;")
standby_mode=$(sql_value "$STANDBY_ALIAS" "SELECT open_mode FROM v\$database;")
standby_switch=$(sql_value "$STANDBY_ALIAS" "SELECT switchover_status FROM v\$database;")
standby_mrp=$(sql_value "$STANDBY_ALIAS" "SELECT COUNT(*) FROM v\$managed_standby WHERE process LIKE 'MRP%';")
standby_seq=$(sql_value "$STANDBY_ALIAS" "SELECT NVL(MAX(sequence#),0) FROM v\$archived_log WHERE applied = 'YES';")
apply_lag=$(sql_value "$STANDBY_ALIAS" "SELECT VALUE FROM v\$dataguard_stats WHERE name = 'apply lag';")
transport_lag=$(sql_value "$STANDBY_ALIAS" "SELECT VALUE FROM v\$dataguard_stats WHERE name = 'transport lag';")
log_info "STANDBY role=${standby_role} open=${standby_mode} switchover_status=${standby_switch} seq_aplicado=${standby_seq} mrp=${standby_mrp}."
log_info "Lags -> transport=${transport_lag} apply=${apply_lag}."

if [[ "$standby_role" != "PHYSICAL STANDBY" ]]; then
  log_error "El alias ${STANDBY_ALIAS} no está en rol PHYSICAL STANDBY."
  STATUS=1
fi

if [[ "$standby_mrp" -eq 0 ]]; then
  log_error "MRP0 no está activo en ${STANDBY_ALIAS}."
  STATUS=1
else
  log_success "MRP activo en ${STANDBY_ALIAS}."
fi

primary_seq=${primary_seq:-0}
standby_seq=${standby_seq:-0}
diff=$(( primary_seq - standby_seq ))
if (( diff < 0 )); then diff=$(( -diff )); fi
log_info "Diferencia de secuencias entre primary y standby: ${diff}."
if (( diff > 1 )); then
  log_warn "El standby se encuentra retrasado en ${diff} secuencias."
fi

if [[ "$primary_switch" == "TO STANDBY" || "$primary_switch" == "SESSIONS_ACTIVE" ]]; then
  log_success "Primary listo para switchover."
else
  log_error "Primary no reporta estado adecuado para switchover (${primary_switch})."
  STATUS=1
fi

if [[ "$standby_switch" == "TO PRIMARY" || "$standby_switch" == "SESSIONS_ACTIVE" ]]; then
  log_success "Standby listo para switchover."
else
  log_error "Standby no reporta estado adecuado para switchover (${standby_switch})."
  STATUS=1
fi

if (( STATUS == 0 )); then
  log_success "Validación Data Guard completada sin observaciones."
else
  log_warn "Validación Data Guard detectó inconsistencias (ver detalles)."
fi

exit "$STATUS"
