#!/bin/bash

# Wrapper para mantener compatibilidad con scripts existentes.
exec /opt/oracle/scripts/common/wait-for-service.sh "$@"
