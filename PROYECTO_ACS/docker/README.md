# Oracle Data Guard 19c (Docker Stack)

Laboratorio Docker con una base primaria y una standby Oracle 19c. Los contenedores comparten volumenes para datos, archivelogs y respaldos, mientras que la automatizacion vive en `oracle19c/scripts/automation`.

## Componentes principales

- `docker-compose.yml`: define los servicios `oracle_primary` y `oracle_standby` y la red `oracle-net`.
- `data/`: volumenes de datos montados por Docker (ignorados en git).
  - `primary/`, `standby/`: oradata de cada instancia.
  - `shared/`: archivelogs, backups y archivo `tnsnames_unified.ora` accesible para ambos contenedores (versión fuente en `oracle19c/config`).
- `oracle19c/scripts/automation/`:
  - `sync_environment.ps1`: prepara carpetas ignoradas por git y copia `tnsnames_unified.ora`.
  - `dataguard_complete.ps1`: punto de entrada unico para switch, transferencia, respaldos, purga, estado y demo.
  - `task_scheduler_complete.ps1`: instala o elimina las tareas programadas en Windows (PowerShell como administrador).
  - `profesor_demo.ps1`: recorrido guiado para demostrar la solucion.
  - `check_status.ps1`, `test_tns_simple.ps1`, `test_tns_connections.ps1`: utilidades de diagnostico rapido.

## Puertos expuestos

| Servicio | Host | Contenedor | Comentario |
|----------|------|------------|------------|
| Base primaria | `1523` | `oracle_primary:1521` | SID `ORCL` |
| Base standby | `1524` | `oracle_standby:1521` | SID `STBY` |
| Enterprise Manager primario | `8080` | `oracle_primary:5500` | APEX/EM |
| Enterprise Manager standby | `8081` | `oracle_standby:5500` | APEX/EM |

## Inicio rapido

```powershell
# 0. Posicionarse en la carpeta del stack
cd docker

# 1. Preparar carpetas ignoradas y archivo TNS
./oracle19c/scripts/automation/sync_environment.ps1

# 2. Arrancar contenedores
docker compose up -d

# 3. Esperar a que Oracle inicialice (~10 min) y revisar estado
cd oracle19c\scripts\automation
./check_status.ps1

# 4. Ejecutar un ciclo completo de automatizacion
./dataguard_complete.ps1 -Action full-cycle
```

## Automatizacion

`dataguard_complete.ps1` agrupa todas las acciones:

```powershell
./dataguard_complete.ps1 -Action switch     # Genera archivelog
./dataguard_complete.ps1 -Action transfer   # Aplica logs en standby
./dataguard_complete.ps1 -Action backup     # RMAN backup + copia a shared
./dataguard_complete.ps1 -Action purge      # Limpia archivos mayores a 3 dias
./dataguard_complete.ps1 -Action status     # Resumen de Data Guard
./dataguard_complete.ps1 -Action demo       # Ruta guiada para revision
```

Para programar estas tareas en Windows (usar PowerShell como administrador):

```powershell
./task_scheduler_complete.ps1 -Operation install
./task_scheduler_complete.ps1 -Operation status
```

Los logs de automatizacion se escriben en `C:\temp\dataguard_logs\dataguard_complete.log`.

## Mantenimiento y verificacion

- Conexiones directas: `docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba` (igual para standby).
- Validar en standby: `SELECT MAX(sequence#) FROM v$archived_log WHERE applied='YES';`.
- Respaldos en `data/shared/backups/` y archivelogs en `data/shared/archivelogs/`.

## Limpieza

Si necesitas reconstruir el entorno desde cero:

```powershell
docker compose down
Remove-Item data\primary -Recurse -Force
Remove-Item data\standby -Recurse -Force
Remove-Item data\shared -Recurse -Force
```

Al volver a `docker compose up -d`, los contenedores se inicializaran desde cero.

---

Documentación detallada: consulta `../../docs/dataguard/manual_dataguard_completo.md`.
