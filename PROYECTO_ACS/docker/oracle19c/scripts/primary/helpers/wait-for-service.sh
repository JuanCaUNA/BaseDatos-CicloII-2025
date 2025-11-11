#!/bin/bash

# Wrapper para mantener compatibilidad con scripts existentes.
# Redirige al helper común que valida servicios de listener/TNS.
exec /opt/oracle/scripts/common/wait-for-service.sh "$@"
