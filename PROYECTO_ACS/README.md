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
| `deploy_dataguard.ps1` | Provisiona la pareja primary/standby y verifica el duplicate |
| `dataguard_complete.ps1` | CLI para estado, switch, transferencia, backup, purge, validate, switchover, failover y logs |
| `failover_dataguard.ps1` | Failover asistido (uso manual en caso de desastre) |
| `sync_environment.ps1` | Crea/actualiza la estructura local (shared, oradata, tnsnames) |
| `test_tns_simple.ps1`, `test_tns_connections.ps1` | Pruebas de conectividad |

> Los volúmenes generados por Oracle viven en `docker/shared/`, `docker/oradata_primary/` y `docker/oradata_standby/`, y se ignoran en git.

## Puesta en marcha rapida

```powershell
# 1. Preparar carpetas ignoradas y archivo TNS
cd docker
./oracle19c/scripts/automation/sync_environment.ps1

# 2. Desplegar y validar Data Guard
./oracle19c/scripts/automation/deploy_dataguard.ps1

# 3. Revisar el estado tras el despliegue
./oracle19c/scripts/automation/dataguard_complete.ps1 -Action status

# 4. Validar transportes y aplicacion
./oracle19c/scripts/automation/dataguard_complete.ps1 -Action validate
```

Los logs de automatización se escriben en `docker/shared/logs/` (se monta dentro de cada contenedor).

## Diagnostico y mantenimiento

- Conexiones SQL directas: `docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba` (igual para standby).
- Respaldos y archivelogs: `docker/shared/` (subcarpetas `backups`, `logs`, `state`).
- Reconstrucción rápida: `docker compose down` y eliminación de `docker/shared/`, `docker/oradata_primary/` y `docker/oradata_standby/` antes de volver a `docker compose up -d`.

## Documentacion de apoyo

- `docs/dataguard/manual_dataguard_completo.md`: procedimiento completo.
- `docs/dataguard/revision_final_data_guard.md`: resumen de cumplimiento.
- `docs/dataguard/standby_manual.md`: guía para la standby.

Proyecto desarrollado con fines académicos para la materia Base de Datos (Ciclo II 2025).

