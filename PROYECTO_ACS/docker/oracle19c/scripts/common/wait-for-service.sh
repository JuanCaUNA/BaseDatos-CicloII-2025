#!/bin/bash
set -euo pipefail

# Espera a que un servicio de listener o entrada TNS se encuentre disponible.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

host="localhost"
port="1521"
service=""
alias=""
method="auto"
timeout=180
interval=5

usage() {
  cat <<'EOF'
Uso: wait-for-service.sh --service <nombre> [opciones]
  --host <host>           Host o IP del listener (por defecto localhost)
  --port <puerto>         Puerto del listener (por defecto 1521)
  --alias <tns_alias>     Alias TNS a validar mediante tnsping
  --method <auto|lsnrctl|tnsping>
  --timeout <segundos>    Tiempo máximo de espera (por defecto 180)
  --interval <segundos>   Intervalo entre intentos (por defecto 5)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service)
      service="$2"
      shift 2
      ;;
    --host)
      host="$2"
      shift 2
      ;;
    --port)
      port="$2"
      shift 2
      ;;
    --alias)
      alias="$2"
      shift 2
      ;;
    --method)
      method="$2"
      shift 2
      ;;
    --timeout)
      timeout="$2"
      shift 2
      ;;
    --interval)
      interval="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_error "Parámetro desconocido: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$service" ]]; then
  log_error "Debe especificar --service."
  usage
  exit 2
fi

require_command lsnrctl
require_command tnsping

if [[ "$method" == "auto" ]]; then
  if [[ -n "$alias" ]]; then
    method="tnsping"
  elif [[ "$host" == "localhost" || "$host" == "127."* ]]; then
    method="lsnrctl"
  else
    method="tnsping"
  fi
fi

if [[ "$method" != "lsnrctl" && "$method" != "tnsping" ]]; then
  log_error "Método no soportado: ${method}"
  exit 2
fi

local_descriptor="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${host})(PORT=${port})))"
local_alias="${alias:-//${host}:${port}/${service}}"

log_info "Esperando servicio ${service} con método ${method} (timeout ${timeout}s)."
end_time=$((SECONDS + timeout))

until (( SECONDS >= end_time )); do
  if [[ "$method" == "lsnrctl" ]]; then
    if lsnrctl services "$local_descriptor" 2>/dev/null | grep -iq "Service \"${service}\""; then
      log_success "Servicio ${service} disponible."
      exit 0
    fi
  else
    if tnsping "$local_alias" >/dev/null 2>&1; then
      log_success "Servicio ${service} disponible."
      exit 0
    fi
  fi
  sleep "$interval"
  log_info "Servicio ${service} aún no disponible, reintentando..."
done

log_error "Tiempo de espera agotado esperando el servicio ${service}."
exit 1
