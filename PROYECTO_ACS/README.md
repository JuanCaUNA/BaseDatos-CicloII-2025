# Proyecto ACS - Oracle Data Guard 19c

Implementacion academica de Oracle Data Guard 19c usando Docker y PowerShell para el Sistema de Administracion de Centros de Salud (ACS).

## Estructura general

```text
PROYECTO_ACS/
├── docker/oracle19c/
├── DOCS/
└── SRC/
```

Elementos destacados:

- `docker/oracle19c/docker-compose.yml`: define los contenedores `oracle_primary` y `oracle_standby`.
- `docker/oracle19c/scripts/automation/`: scripts PowerShell enfocados en Data Guard.
- `DOCS/manual_dataguard_completo.md`: documentacion tecnica detallada.
- `SRC/ACS_SCRIPT_COMPLETO.sql`: script principal del sistema ACS.

## Scripts de automatizacion

| Script | Uso principal |
|--------|---------------|
| `dataguard_complete.ps1` | Switch, transferencia, backup, purge, estado y demo |
| `task_scheduler_complete.ps1` | Instala o quita las tareas programadas en Windows |
| `profesor_demo.ps1` | Demostracion guiada para la evaluacion |
| `check_status.ps1` | Resumen rapido de contenedores y logs |
| `test_tns_simple.ps1`, `test_tns_connections.ps1` | Pruebas de conectividad |

> Los volumenes generados por Oracle viven en `docker/oracle19c/data/` y se ignoran en git.

## Puesta en marcha rapida

```powershell
# 1. Arrancar los contenedores
cd docker/oracle19c
docker compose up -d

# 2. Revisar estado de la instalacion inicial
cd scripts/automation
./check_status.ps1

# 3. Ejecutar un ciclo de Data Guard
./dataguard_complete.ps1 -Action full-cycle
```

Para programar las tareas en Windows:

```powershell
./task_scheduler_complete.ps1 -Operation install
./task_scheduler_complete.ps1 -Operation status
```

Los logs de automatizacion se escriben en `C:\temp\dataguard_logs\`.

## Diagnostico y mantenimiento

- Conexiones SQL directas: `docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba` (igual para standby).
- Respaldos y archivelogs: `docker/oracle19c/data/shared/`.
- Reconstruccion rapida: `docker compose down` y eliminacion de `docker/oracle19c/data/` antes de volver a `docker compose up -d`.

## Documentacion de apoyo

- `DOCS/manual_dataguard_completo.md`: procedimiento completo.
- `DOCS/revision_final_data_guard.md`: resumen de cumplimiento.
- `DOCS/standby_manual.md`: guia para la standby.

Proyecto desarrollado con fines academicos para la materia Base de Datos (Ciclo II 2025).

