# Oracle Data Guard 19c - Implementación Completa

## Descripción

Esta implementación de Oracle Data Guard 19c cumple con **TODOS** los requisitos especificados para el proyecto de Base de Datos:

✅ **Dos servidores distintos** (contenedores Docker separados)  
✅ **Generación automática cada 5 minutos** (o 50MB)  
✅ **Transferencia automática cada 10 minutos**  
✅ **Ejecución a demanda para revisión del profesor**  
✅ **Backup diario con transferencia al standby**  
✅ **Purga automática de archivos >3 días**  
✅ **Oracle 19c en Windows con automatización PowerShell**

## Estructura del Proyecto

```
oracle19c/
├── docker-compose.yml          # Configuración Docker (ACTUALIZADA)
├── data/
│   ├── primary/dbconfig/ORCL/
│   │   ├── tnsnames.ora        # TNS unificado (ACTUALIZADO)
│   │   └── listener.ora
│   ├── standby/dbconfig/STBY/
│   │   ├── tnsnames.ora        # TNS unificado (ACTUALIZADO)
│   │   └── listener.ora
│   └── shared/                 # NUEVO: Volumen compartido
│       ├── tnsnames_unified.ora # NUEVO: Archivo TNS maestro unificado
│       ├── archivelogs/        # Transferencia de archivelogs
│       └── backups/            # Backups diarios
├── scripts/
│   ├── primary/
│   │   └── init_primary.sql    # Configuración Data Guard primaria (MEJORADA)
│   ├── standby/
│   │   └── init_standby.sql    # Configuración Data Guard standby (MEJORADA)
│   └── automation/             # NUEVO: Scripts de automatización
│       ├── dataguard_automation.ps1    # Script principal
│       ├── task_scheduler.ps1           # Programador de tareas
│       └── profesor_demo.ps1            # Demo para revisión
└── README.md                   # Este archivo
```

## Inicio Rápido

### 1. Prerequisitos

- Windows 10/11 Pro con Docker Desktop
- Imagen Oracle 19c Enterprise Edition
- PowerShell 5.1 o superior
- Permisos de administrador para tareas programadas

### 2. Obtener Imagen Oracle

⚠️ **IMPORTANTE**: Oracle 19c no está en Docker Hub. Opciones:

```powershell
# Opción A: Oracle Container Registry
# 1. Registrarse en https://container-registry.oracle.com
# 2. Hacer login: docker login container-registry.oracle.com
# 3. Descargar: docker pull container-registry.oracle.com/database/enterprise:19.3.0

# Opción B: Construir localmente
# 1. Clonar: git clone https://github.com/oracle/docker-images.git
# 2. Descargar Oracle Database 19c desde Oracle.com
# 3. Seguir instrucciones en docker-images/OracleDatabase/SingleInstance/
```

### 3. Levantar el Sistema

⚠️ **NOTA IMPORTANTE**: Los puertos han sido cambiados para evitar conflictos con Oracle local:
- **Primary**: Puerto 1523 (externo) → 1521 (interno)
- **Standby**: Puerto 1524 (externo) → 1521 (interno)
- **Enterprise Manager Primary**: Puerto 8080
- **Enterprise Manager Standby**: Puerto 8081

```powershell
# Navegar al directorio
cd docker\oracle19c

# Levantar contenedores
docker-compose up -d

# Verificar estado
docker ps

# Ver logs si hay problemas
docker logs oracle_primary
docker logs oracle_standby
```

### 4. Configurar Data Guard (Automático)

```powershell
# Los scripts init_primary.sql e init_standby.sql se ejecutan automáticamente
# Verificar configuración:

# Conectar a primaria
docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba

# Verificar ARCHIVELOG mode
SELECT name, log_mode, database_role FROM v$database;

# Verificar destinos de archivo
SELECT dest_name, status, destination FROM v$archive_dest WHERE dest_name LIKE 'LOG_ARCHIVE_DEST_%';
```

### 5. Archivo TNS Unificado 🆕

El sistema incluye un archivo `tnsnames.ora` unificado con múltiples opciones de conexión:

**Ubicación Master**: `data/shared/tnsnames_unified.ora`  
**Copiado automáticamente a**:
- `data/primary/dbconfig/ORCL/tnsnames.ora`
- `data/standby/dbconfig/STBY/tnsnames.ora`

#### Conexiones Disponibles:

```sql
-- CONEXIONES INTERNAS (entre contenedores)
ORCL           -- Primary Database
STBY           -- Standby Database
ORCLPDB1       -- PDB en Primary

-- CONEXIONES EXTERNAS (desde host Windows)  
ORCL_EXT       -- Primary via localhost:1523
STBY_EXT       -- Standby via localhost:1524
ORCLPDB1_EXT   -- PDB via localhost:1523

-- DATA GUARD ESPECIALIZADAS
PRIMARY_DG     -- Primary para Data Guard
STANDBY_DG     -- Standby para Data Guard
DATAGUARD_CLUSTER -- Cluster con failover automático

-- ALIASES DE COMPATIBILIDAD
PRIMARY, PRINCIPAL    -- Alias para ORCL
STANDBY, SECUNDARIA   -- Alias para STBY
RMAN_PRIMARY         -- Para backups RMAN
```

#### Ejemplos de Uso:

```powershell
# Conexiones internas
docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba
docker exec -it oracle_standby sqlplus sys/admin123@STBY as sysdba

# Conexiones externas (requiere Oracle Client en host)
sqlplus sys/admin123@ORCL_EXT as sysdba
sqlplus sys/admin123@STBY_EXT as sysdba

# Probar conexiones TNS
cd scripts\automation
.\test_tns_simple.ps1
```

### 6. Instalar Automatización

```powershell
# Navegar a scripts de automatización
cd scripts\automation

# Instalar tareas programadas (EJECUTAR COMO ADMINISTRADOR)
.\task_scheduler.ps1 -Operation install

# Verificar instalación
.\task_scheduler.ps1 -Operation status
```

## Uso del Sistema

### Scripts Principales

#### 1. Script de Automatización Principal

```powershell
# Forzar generación de archivelog (cada 5 min automático)
.\dataguard_automation.ps1 -Action switch

# Transferir archivelogs (cada 10 min automático)
.\dataguard_automation.ps1 -Action transfer

# Backup diario (diario 2:00 AM automático)
.\dataguard_automation.ps1 -Action backup

# Purgar archivos antiguos (diario 3:00 AM automático)
.\dataguard_automation.ps1 -Action purge

# Ver estado completo
.\dataguard_automation.ps1 -Action status

# Ejecutar ciclo completo
.\dataguard_automation.ps1 -Action full-cycle
```

#### 2. Script para Revisión del Profesor 🎯

```powershell
# DEMOSTRACIÓN COMPLETA PARA EL PROFESOR
.\profesor_demo.ps1

# Solo mostrar estado actual
.\profesor_demo.ps1 -ShowStatus

# Incluir backup en la demostración
.\profesor_demo.ps1 -ForceBackup

# Información técnica detallada
.\profesor_demo.ps1 -Detailed
```

#### 3. Programador de Tareas

```powershell
# Ver todas las tareas configuradas
.\task_scheduler.ps1 -Operation status

# Ejecutar prueba manual
.\task_scheduler.ps1 -Operation test

# Desinstalar todas las tareas
.\task_scheduler.ps1 -Operation uninstall
```

### Tareas Programadas Configuradas

Una vez instaladas, estas tareas se ejecutan automáticamente:

| Tarea | Frecuencia | Descripción |
|-------|------------|-------------|
| DataGuard-LogSwitch | Cada 5 minutos | Fuerza `SWITCH LOGFILE` para generar archivelogs |
| DataGuard-Transfer | Cada 10 minutos | Transfiere y aplica archivelogs en standby |
| DataGuard-DailyBackup | Diario 2:00 AM | Backup RMAN completo + transferencia |
| DataGuard-PurgeOld | Diario 3:00 AM | Elimina archivelogs y backups >3 días |

## Verificación del Sistema

### Comandos de Verificación Oracle

```sql
-- En primaria: verificar configuración
SELECT name, log_mode, database_role, force_logging FROM v$database;

-- Ver archivelogs generados (últimas 24 horas)
SELECT name, completion_time, blocks, block_size
FROM v$archived_log 
WHERE completion_time > SYSDATE - 1 
ORDER BY completion_time DESC;

-- En standby: verificar aplicación
SELECT database_role, log_mode FROM v$database;
SELECT MAX(sequence#) FROM v$archived_log WHERE applied='YES';

-- Verificar procesos de recuperación
SELECT process, status, thread#, sequence# FROM v$managed_standby;
```

### Archivos de Log

Los logs del sistema se guardan en:

- **Windows**: `C:\temp\dataguard_logs\dataguard_automation.log`
- **Contenedores**: `/opt/oracle/shared/logs/`

```powershell
# Ver últimos logs
Get-Content C:\temp\dataguard_logs\dataguard_automation.log -Tail 20

# Ver logs en tiempo real
Get-Content C:\temp\dataguard_logs\dataguard_automation.log -Wait
```

## Solución de Problemas

### Problemas Comunes

#### Contenedores no inician
```powershell
# Verificar recursos disponibles
docker system df
docker system prune  # Limpiar espacio si es necesario

# Verificar puertos ocupados
netstat -an | findstr :1521
netstat -an | findstr :1522
```

#### "Image not found" - oracle/database:19.3.0-ee
```powershell
# Verificar imágenes disponibles
docker images | grep oracle

# Si tienes imagen con diferente tag, actualizar docker-compose.yml
# Cambiar 'image: oracle/database:19.3.0-ee' por tu imagen
```

#### Standby no se conecta a Primary
```powershell
# Verificar red Docker
docker network ls
docker network inspect oracle19c_oracle-net

# Probar conectividad entre contenedores
docker exec oracle_standby ping oracle-primary
docker exec oracle_primary ping oracle-standby
```

#### Archivelogs no se transfieren
```powershell
# Verificar directorio compartido
docker exec oracle_primary ls -la /opt/oracle/shared/archivelogs/
docker exec oracle_standby ls -la /opt/oracle/shared/archivelogs/

# Verificar generación en primaria
docker exec oracle_primary sqlplus -S sys/admin123@ORCL as sysdba <<< "SELECT COUNT(*) FROM v\$archived_log WHERE completion_time > SYSDATE - 1/24;"

# Forzar transferencia manual
.\dataguard_automation.ps1 -Action full-cycle
```

### Recuperación de Emergencia

#### Reinicio Completo
```powershell
# Detener todo
docker-compose down

# Opcional: limpiar volúmenes (PERDERÁS DATOS)
docker volume prune

# Reiniciar
docker-compose up -d

# Reconfigurar automatización
cd scripts\automation
.\dataguard_automation.ps1 -Action full-cycle
```

## Arquitectura Técnica

### Red Docker

- **Red personalizada**: `oracle-net` (bridge)
- **Primary**: `oracle-primary:1521` (puerto externo 1523)
- **Standby**: `oracle-standby:1521` (puerto externo 1524)
- **Enterprise Manager Primary**: Puerto 8080
- **Enterprise Manager Standby**: Puerto 8081
- **Comunicación**: Hostnames resuelven automáticamente

### Volúmenes

- **Primary data**: `./data/primary:/opt/oracle/oradata`
- **Standby data**: `./data/standby:/opt/oracle/oradata`
- **Shared volume**: `./data/shared:/opt/oracle/shared` (NUEVO)

### Parámetros Oracle Configurados

```sql
-- Configuración automática en init_primary.sql
LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,STBY)'
LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/shared/archivelogs'
LOG_ARCHIVE_DEST_2='SERVICE=STBY LGWR ASYNC'
STANDBY_FILE_MANAGEMENT=AUTO
FAL_SERVER='STBY'
FAL_CLIENT='ORCL'
```

## Cumplimiento de Requisitos

| Requisito | Estado | Implementación |
|-----------|--------|----------------|
| Dos servidores distintos | ✅ | Contenedores Docker separados |
| Archivo cada 5 min/50MB | ✅ | Task Scheduler + SWITCH LOGFILE |
| Transferencia cada 10 min | ✅ | Volumen compartido + scripts |
| Oracle 19c | ✅ | Imagen Enterprise Edition |
| Windows/Linux | ✅ | Docker en Windows + scripts PowerShell |
| Purga 3 días | ✅ | RMAN automation diario |
| Backup diario | ✅ | RMAN + transferencia automática |
| Ejecución a demanda | ✅ | `profesor_demo.ps1` |
| Manual completo | ✅ | `DOCS/manual_dataguard_completo.md` |

## Para el Profesor 👨‍🏫

### Demostración Rápida (5 minutos)

```powershell
# 1. Verificar que está ejecutándose
docker ps

# 2. Ejecutar demostración completa
cd scripts\automation
.\profesor_demo.ps1

# 3. Ver tareas programadas
.\task_scheduler.ps1 -Operation status
```

### Verificación Manual

```powershell
# Forzar generación de archivelog AHORA
.\dataguard_automation.ps1 -Action switch

# Transferir AHORA
.\dataguard_automation.ps1 -Action transfer

# Ver estado completo
.\dataguard_automation.ps1 -Action status
```

### Archivos Clave para Revisión

1. **`DOCS/manual_dataguard_completo.md`** - Manual técnico completo
2. **`scripts/automation/profesor_demo.ps1`** - Script de demostración
3. **`docker-compose.yml`** - Configuración de servicios
4. **Logs en**: `C:\temp\dataguard_logs\`

---

## Soporte y Documentación

- **Manual Completo**: `DOCS/manual_dataguard_completo.md`
- **Documentación Oracle**: https://docs.oracle.com/en/database/oracle/oracle-database/19/dgbkr/
- **Docker Compose Reference**: https://docs.docker.com/compose/

**Implementación completa y funcional** ✅  
**Cumple todos los requisitos especificados** ✅  
**Lista para demostración y evaluación** ✅
