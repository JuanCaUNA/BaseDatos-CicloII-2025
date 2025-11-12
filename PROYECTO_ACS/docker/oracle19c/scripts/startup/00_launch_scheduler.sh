#!/bin/bash
set -euo pipefail

# Arranca el scheduler de tareas recurrentes en cada inicio del contenedor.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-${ORACLE_SID:-ORCL}}
source /opt/oracle/scripts/common/lib.sh

SCHEDULER="/opt/oracle/scripts/automation/task_scheduler.sh"
if [[ ! -x "$SCHEDULER" ]]; then
  log_warn "Scheduler no disponible en ${SCHEDULER}."
  exit 0
fi

log_info "Invocando scheduler de Data Guard (${SCHEDULER})."
nohup "$SCHEDULER" >>"${LOG_ROOT}/task_scheduler.invocation.log" 2>&1 &
exit 0
