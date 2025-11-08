# Proyecto ACS - Oracle Data Guard 19c

Implementación académica de Oracle Data Guard 19c usando Docker y PowerShell para el Sistema de Administración de Centros de Salud (ACS).

## Estructura general

```text
PROYECTO_ACS/
├── docs/
│   ├── dataguard/
│   ├── oracle/
│   ├── correo/
│   └── reference/
├── docker/
│   ├── docker-compose.yml
│   └── oracle19c/
└── src/
    ├── database/
    └── modules/
```

Elementos destacados:

- `docker/docker-compose.yml`: define los contenedores `oracle_primary` y `oracle_standby`.
- `docker/oracle19c/scripts/automation/`: scripts PowerShell enfocados en Data Guard.
- `docker/oracle19c/config/tnsnames_unified.ora`: archivo fuente para sincronizar TNS en los contenedores.
- `docs/dataguard/manual_dataguard_completo.md`: documentación técnica detallada.
- `src/database/acs_script_completo.sql`: script principal del sistema ACS.

## Scripts de automatizacion

| Script | Uso principal |
|--------|---------------|
| `dataguard_complete.ps1` | Switch, transferencia, backup, purge, estado y demo |
| `task_scheduler_complete.ps1` | Instala o quita las tareas programadas en Windows |
| `profesor_demo.ps1` | Demostración guiada para la evaluación |
| `check_status.ps1` | Resumen rápido de contenedores y logs |
| `test_tns_simple.ps1`, `test_tns_connections.ps1` | Pruebas de conectividad |

> Los volúmenes generados por Oracle viven en `docker/data/` y se ignoran en git.

## Puesta en marcha rapida

```powershell
# 1. Preparar carpetas ignoradas y archivo TNS
cd docker
./oracle19c/scripts/automation/sync_environment.ps1

# 2. Arrancar los contenedores
docker compose up -d

# 3. Revisar estado de la instalación inicial
cd oracle19c/scripts/automation
./check_status.ps1

# 4. Ejecutar un ciclo de Data Guard
./dataguard_complete.ps1 -Action full-cycle
```

Para programar las tareas en Windows:

```powershell
./task_scheduler_complete.ps1 -Operation install
./task_scheduler_complete.ps1 -Operation status
```

Los logs de automatización se escriben en `C:\temp\dataguard_logs\`.

## Diagnostico y mantenimiento

- Conexiones SQL directas: `docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba` (igual para standby).
- Respaldos y archivelogs: `docker/data/shared/`.
- Reconstrucción rápida: `docker compose down` y eliminación de `docker/data/` antes de volver a `docker compose up -d`.

## Documentacion de apoyo

- `docs/dataguard/manual_dataguard_completo.md`: procedimiento completo.
- `docs/dataguard/revision_final_data_guard.md`: resumen de cumplimiento.
- `docs/dataguard/standby_manual.md`: guía para la standby.

Proyecto desarrollado con fines académicos para la materia Base de Datos (Ciclo II 2025).

