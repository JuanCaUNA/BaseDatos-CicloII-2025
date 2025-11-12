#!/bin/bash
set -euo pipefail

DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-STBY}
source /opt/oracle/scripts/common/lib.sh

LOG="${LOG_ROOT}/init_standby.log"
ERR="${LOG_ROOT}/init_standby.errors"
STATUS="${STATE_ROOT}/init_standby.status"

: "${LOG_ROOT:?LOG_ROOT no definido}"
: "${STATE_ROOT:?STATE_ROOT no definido}"

touch "$LOG"
chmod 640 "$LOG" 2>/dev/null || true

grep -E 'ORA-[0-9]{5}' "$LOG" | grep -v 'ORA-00000' >"$ERR" 2>/dev/null || true

if [[ -s "$ERR" ]]; then
  echo "[STANDBY][ERROR] Se detectaron errores ORA en init_standby.log (ver init_standby.errors)." | tee -a "$LOG"
  exit 20
fi

rm -f "$ERR"
echo "[STANDBY][OK] Ejecución completada sin ORA detectados." | tee -a "$LOG"
date '+%Y-%m-%d %H:%M:%S OK' >"$STATUS"
chmod 640 "$STATUS" 2>/dev/null || true
