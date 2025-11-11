#!/bin/bash
set -euo pipefail

# Crea o actualiza el tnsnames.ora requerido por primary y standby.
DEFAULT_ORACLE_SID=${DEFAULT_ORACLE_SID:-ORCL}
source /opt/oracle/scripts/common/lib.sh

TNS_DIR="${TNS_ADMIN}"
TARGET="${TNS_DIR}/tnsnames.ora"
TEMPLATE="/opt/oracle/config/tnsnames.ora"

mkdir -p "$TNS_DIR"

normalize_file() {
  tr '\n' ' ' < "$1" | tr -s ' '
}

needs_update=true
if [[ -f "$TARGET" ]]; then
  normalized=$(normalize_file "$TARGET")
  if [[ "$normalized" =~ ORCL[[:space:]]*=[^=]*HOST[[:space:]]*=[[:space:]]*oracle-primary[^=]*SERVICE_NAME[[:space:]]*=[[:space:]]*ORCL ]] \
     && [[ "$normalized" =~ STBY[[:space:]]*=[^=]*HOST[[:space:]]*=[[:space:]]*oracle-standby[^=]*SERVICE_NAME[[:space:]]*=[[:space:]]*STBY ]]; then
    if [[ "$normalized" =~ ORCL[[:space:]]*=[^=]*SID[[:space:]]*=[[:space:]]*ORCL ]] \
       && [[ "$normalized" =~ STBY[[:space:]]*=[^=]*SID[[:space:]]*=[[:space:]]*STBY ]]; then
      needs_update=false
    fi
  fi
fi

if [[ "$needs_update" == false ]]; then
  log_info "tnsnames.ora ya contiene las entradas requeridas."
  exit 0
fi

tmp_file=$(mktemp)

if [[ -f "$TEMPLATE" ]]; then
  cat "$TEMPLATE" > "$tmp_file"
  echo "" >> "$tmp_file"
else
  cat <<'EOF' > "$tmp_file"
# tnsnames.ora generado automáticamente
EOF
fi

cat <<'EOF' >> "$tmp_file"

# Entradas requeridas para Data Guard
ORCL =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-primary)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCL)
      (SID = ORCL)
    )
  )

STBY =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-standby)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = STBY)
      (SID = STBY)
    )
  )
EOF

mv "$tmp_file" "$TARGET"
chown oracle:oinstall "$TARGET" 2>/dev/null || true
chmod 640 "$TARGET" 2>/dev/null || true

log_success "tnsnames.ora actualizado con alias ORCL y STBY."
