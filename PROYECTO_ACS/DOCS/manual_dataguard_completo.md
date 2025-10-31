# Manual de Implementación Oracle Data Guard 19c

## Sistema de Base de Datos Standby Automatizado

### Resumen Ejecutivo

Este manual documenta la implementación completa de una solución Oracle Data Guard 19c usando Docker, que cumple con todos los requisitos especificados para la asignatura de Base de Datos. La solución incluye:

✅ **Dos servidores distintos** (contenedores Docker separados)  
✅ **Generación automática de archivelogs cada 5 minutos**  
✅ **Transferencia automática cada 10 minutos**  
✅ **Ejecución a demanda para revisiones**  
✅ **Backup diario automatizado**  
✅ **Purga automática de archivos >3 días**  
✅ **Oracle 19c en Windows con Docker**  
✅ **Documentación completa y funcional**

### Introducción

Oracle Data Guard es la solución empresarial de Oracle para alta disponibilidad, protección de datos y recuperación ante desastres. Permite mantener una o más copias de una base de datos de producción (standby databases) que se sincronizan automáticamente con la base de datos primaria.

#### Conceptos Fundamentales

- **Data Guard**: Conjunto de servicios, aplicaciones y configuraciones que crean, mantienen y monitorean una o más bases de datos standby.
- **Base de datos Primaria**: La base de datos de producción que recibe todas las transacciones de usuarios y aplicaciones.
- **Base de datos Standby**: Copia física de la base de datos primaria que se mantiene sincronizada mediante la aplicación de redo logs.
- **Redo Transport**: Servicio que controla la transmisión automática de redo data desde la base primaria hacia las bases standby.
- **Redo Apply**: Proceso que aplica los redo logs recibidos en la base de datos standby para mantenerla sincronizada.
- **ARCHIVELOG Mode**: Modo de operación que permite guardar los redo logs llenos como archivos de archivo, esencial para Data Guard.

### Requisitos Previos

#### Software Requerido
- Windows 10/11 Pro (para Docker Desktop)
- Docker Desktop para Windows (versión 4.0 o superior)
- PowerShell 5.1 o superior
- Oracle Database 19c Enterprise Edition (imagen Docker)
- Mínimo 8GB RAM disponible
- Mínimo 50GB espacio en disco

#### Conocimientos Técnicos
- Administración básica de Oracle Database
- Conceptos de Docker y contenedores
- Uso de PowerShell y scripts
- Configuración de tareas programadas en Windows

### Arquitectura de la Solución

#### Componentes Principales

1. **Contenedor Oracle Primary** (oracle_primary)
   - Puerto: 1521 (externo)
   - Base de datos: ORCL
   - Rol: PRIMARY
   - Genera archivelogs cada 5 minutos

2. **Contenedor Oracle Standby** (oracle_standby)
   - Puerto: 1522 (externo)
   - Base de datos: STBY
   - Rol: PHYSICAL STANDBY
   - Aplica archivelogs recibidos

3. **Volumen Compartido** (/opt/oracle/shared)
   - Directorio para archivelogs
   - Directorio para backups
   - Logs de automatización

4. **Scripts de Automatización**
   - dataguard_complete.ps1: Script principal
   - task_scheduler_complete.ps1: Programador de tareas
   - profesor_demo.ps1: Demostración para revisión

#### Red y Comunicación

Los contenedores se conectan a través de una red Docker Bridge personalizada que permite:
- Resolución de nombres por hostname
- Comunicación directa entre contenedores
- Aislamiento de la red host

### Instalación Paso a Paso

#### Paso 1: Preparar el Entorno

1. **Instalar Docker Desktop**
   ```powershell
   # Descargar desde https://www.docker.com/products/docker-desktop
   # Verificar instalación
   docker --version
   docker-compose --version
   ```

2. **Obtener Imagen Oracle 19c**
   ```powershell
   # Opción 1: Construir desde Oracle Container Registry
   # Seguir instrucciones en: https://github.com/oracle/docker-images
   
   # Opción 2: Si ya tienes la imagen local
   docker images | grep oracle
   ```

3. **Clonar el Proyecto**
   ```powershell
   cd C:\Users\[usuario]\OneDrive\Escritorio\BaseDatos-CicloII-2025\PROYECTO_ACS\docker\oracle19c
   ```

#### Paso 2: Configurar los Archivos

Los archivos ya están configurados correctamente en el repositorio:

- `docker-compose.yml`: Definición de servicios
- `data/primary/dbconfig/ORCL/tnsnames.ora`: Configuración de red primaria
- `data/standby/dbconfig/STBY/tnsnames.ora`: Configuración de red standby
- `scripts/primary/init_primary.sql`: Inicialización primaria
- `scripts/standby/init_standby.sql`: Inicialización standby

#### Paso 3: Levantar los Contenedores

```powershell
# Navegar al directorio
cd docker\oracle19c

# Levantar los servicios
docker-compose up -d

# Verificar que estén ejecutándose
docker ps
```

#### Paso 4: Configurar Data Guard

```powershell
# Ejecutar configuración inicial de primaria
docker exec -it oracle_primary sqlplus sys/admin123@ORCL as sysdba
@/opt/oracle/scripts/setup/init_primary.sql

# Ejecutar configuración inicial de standby
docker exec -it oracle_standby sqlplus sys/admin123@STBY as sysdba
@/opt/oracle/scripts/setup/init_standby.sql
```

#### Paso 5: Instalar Scripts de Automatización

```powershell
# Navegar al directorio de scripts
cd scripts\automation

# Instalar tareas programadas (como Administrador)
.\task_scheduler_complete.ps1 -Operation install
```

### Funcionalidades Implementadas

#### 1. Generación de Archivelogs cada 5 minutos

**Cumplimiento**: ✅ Implementado via tarea programada

La base de datos se configura para generar archivelogs automáticamente cada 5 minutos mediante:

```sql
-- Configuración en init_primary.sql
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='arch_%t_%s_%r.arc' SCOPE=SPFILE;
ALTER SYSTEM SWITCH LOGFILE; -- Ejecutado cada 5 minutos por script
```

**Script**: `dataguard_complete.ps1 -Action switch`  
**Programación**: Cada 5 minutos via Task Scheduler

#### 2. Transferencia cada 10 minutos

**Cumplimiento**: ✅ Implementado via volumen compartido Docker

Los archivelogs se transfieren automáticamente usando:
- Volumen compartido entre contenedores
- Script de transferencia y aplicación
- Verificación de integridad

**Script**: `dataguard_complete.ps1 -Action transfer`  
**Programación**: Cada 10 minutos via Task Scheduler

#### 3. Backup Diario Automatizado

**Cumplimiento**: ✅ Implementado con RMAN

Backup completo diario que incluye:
- Database completa (comprimida)
- Archivelogs
- Control files
- Transferencia automática al standby

**Script**: `dataguard_complete.ps1 -Action backup`  
**Programación**: Diario a las 2:00 AM

#### 4. Purga Automática (3 días)

**Cumplimiento**: ✅ Implementado con RMAN

Limpieza automática de:
- Archivelogs aplicados >3 días (RMAN)
- Archivos físicos >3 días
- Backups >7 días

**Script**: `dataguard_complete.ps1 -Action purge`  
**Programación**: Diario a las 3:00 AM

#### 5. Ejecución a Demanda del Profesor

**Cumplimiento**: ✅ Script especializado para demostración

Script especial que ejecuta:
1. Verificación de prerequisitos
2. Estado actual de las bases de datos
3. Generación forzada de archivelog
4. Transferencia inmediata
5. Backup si se solicita
6. Verificación final
7. Reporte completo

**Script**: `profesor_demo.ps1`

### Uso de los Scripts

#### Script Principal de Automatización

```powershell
# Forzar generación de archivelog
.\dataguard_complete.ps1 -Action switch

# Transferir archivelogs
.\dataguard_complete.ps1 -Action transfer

# Realizar backup
.\dataguard_complete.ps1 -Action backup

# Purgar archivos antiguos
.\dataguard_complete.ps1 -Action purge

# Verificar estado
.\dataguard_complete.ps1 -Action status

# Ciclo completo
.\dataguard_complete.ps1 -Action full-cycle
```

#### Programador de Tareas

```powershell
# Instalar todas las tareas (como Administrador)
.\task_scheduler_complete.ps1 -Operation install

# Ver estado de tareas
.\task_scheduler_complete.ps1 -Operation status

# Desinstalar tareas
.\task_scheduler_complete.ps1 -Operation uninstall

# Ejecutar prueba
.\task_scheduler_complete.ps1 -Operation test
```

#### Script de Demostración para el Profesor

```powershell
# Demostración completa
.\profesor_demo.ps1

# Solo mostrar estado
.\profesor_demo.ps1 -ShowStatus

# Incluir backup en demostración
.\profesor_demo.ps1 -ForceBackup

# Información detallada
.\profesor_demo.ps1 -Detailed
```

### Verificación y Monitoreo

#### Comandos de Verificación

```sql
-- Verificar modo ARCHIVELOG en primaria
SELECT name, log_mode, database_role FROM v$database;

-- Ver archivelogs recientes
SELECT name, completion_time 
FROM v$archived_log 
WHERE completion_time > SYSDATE - 1 
ORDER BY completion_time DESC;

-- Estado del standby
SELECT database_role, log_mode FROM v$database;

-- Archivelogs aplicados
SELECT MAX(sequence#) 
FROM v$archived_log 
WHERE applied='YES';
```

#### Archivos de Log

Los logs se guardan en: `C:\temp\dataguard_logs\`

- `dataguard_complete.log`: Log principal de automatización
- Logs individuales por cada ejecución

### Solución de Problemas

#### Problemas Comunes

**1. Contenedores no inician**
```powershell
# Verificar logs
docker logs oracle_primary
docker logs oracle_standby

# Verificar recursos
docker system df
```

**2. Conexión entre contenedores falla**
```powershell
# Verificar red
docker network ls
docker network inspect oracle19c_oracle-net

# Verificar tnsnames.ora
docker exec oracle_primary cat /opt/oracle/oradata/dbconfig/ORCL/tnsnames.ora
```

**3. Archivelogs no se transfieren**
```powershell
# Verificar directorio compartido
docker exec oracle_primary ls -la /opt/oracle/shared/archivelogs/

# Verificar permisos
docker exec oracle_primary ls -la /opt/oracle/shared/
```

**4. Standby no aplica logs**
```sql
-- Verificar estado de recovery
SELECT process, status FROM v$managed_standby;

-- Reiniciar recovery
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
```

#### Procedimientos de Emergencia

**Reinicio Completo del Sistema**

```powershell
# Detener todo
docker-compose down

# Limpiar volúmenes si es necesario
docker volume prune

# Reiniciar
docker-compose up -d

# Reconfigurar
.\scripts\automation\dataguard_complete.ps1 -Action full-cycle
```

**Recuperación Manual del Standby**

```sql
-- En primaria: crear nuevo control file
ALTER DATABASE CREATE STANDBY CONTROLFILE AS '/opt/oracle/shared/standby_controlfile.ctl';

-- En standby: usar el nuevo control file
STARTUP NOMOUNT;
-- Copiar el control file manualmente
STARTUP MOUNT;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
```

### Recomendaciones de Producción

#### Mejoras para Entorno Productivo

1. **Seguridad**
   - Usar Oracle Wallet para passwords
   - Configurar SSL/TLS para conexiones
   - Implementar auditoría

2. **Red**
   - Usar redes dedicadas para replicación
   - Configurar QoS para tráfico de Data Guard
   - Implementar bonding de interfaces

3. **Almacenamiento**
   - Usar storage compartido (ASM)
   - Configurar FRA (Fast Recovery Area)
   - Implementar snapshots para backups

4. **Monitoreo**
   - Oracle Enterprise Manager
   - Data Guard Broker (DGMGRL)
   - Alertas automáticas

5. **Alta Disponibilidad**
   - Configurar múltiples standby databases
   - Implementar Fast-Start Failover
   - Pruebas regulares de switchover

### Conclusiones

#### Cumplimiento de Requisitos

La implementación desarrollada cumple **100%** con todos los requisitos especificados:

✅ **Dos servidores distintos**: Contenedores Docker separados con redes aisladas  
✅ **Archivos cada 5 minutos**: Implementado via SWITCH LOGFILE automatizado  
✅ **Transferencia cada 10 minutos**: Sistema de volúmenes compartidos con verificación  
✅ **Oracle 19c**: Versión Enterprise Edition en contenedores  
✅ **Windows compatible**: Scripts PowerShell nativos y Task Scheduler  
✅ **Purga 3 días**: RMAN automation con cleanup automático  
✅ **Backup diario**: RMAN full backup con transferencia al standby  
✅ **Ejecución a demanda**: Script especializado para revisión del profesor

#### Beneficios de la Solución

1. **Portabilidad**: Usa Docker para facilitar deployment
2. **Automatización**: Scripts PowerShell para Windows
3. **Monitoreo**: Logs detallados de todas las operaciones
4. **Escalabilidad**: Fácil agregar más standby databases
5. **Mantenimiento**: Procedimientos documentados y automatizados

#### Limitaciones Actuales

1. **Desarrollo**: Optimizada para entorno educativo/demostración
2. **Seguridad**: Passwords en texto plano (no recomendado para producción)
3. **Red**: Usa bridge networks (en producción usar redes dedicadas)
4. **Storage**: Volúmenes locales (en producción usar storage empresarial)

### Anexos

#### A. Estructura de Archivos

```
PROYECTO_ACS/docker/oracle19c/
├── docker-compose.yml
├── data/
│   ├── primary/dbconfig/ORCL/
│   │   ├── tnsnames.ora
│   │   └── listener.ora
│   ├── standby/dbconfig/STBY/
│   │   ├── tnsnames.ora
│   │   └── listener.ora
│   └── shared/
│       ├── archivelogs/
│       └── backups/
├── scripts/
│   ├── primary/init_primary.sql
│   ├── standby/init_standby.sql
│   └── automation/
│       ├── dataguard_complete.ps1
│       ├── task_scheduler_complete.ps1
│       └── profesor_demo.ps1
└── README.md
```

#### B. Parámetros Oracle Configurados

```sql
-- Parámetros Data Guard Primaria
DB_UNIQUE_NAME='ORCL'
LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,STBY)'
LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/shared/archivelogs'
LOG_ARCHIVE_DEST_2='SERVICE=STBY LGWR ASYNC'
LOG_ARCHIVE_FORMAT='arch_%t_%s_%r.arc'
LOG_ARCHIVE_MAX_PROCESSES=5
STANDBY_FILE_MANAGEMENT=AUTO
FAL_SERVER='STBY'
FAL_CLIENT='ORCL'

-- Parámetros Data Guard Standby
DB_UNIQUE_NAME='STBY'
LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,STBY)'
LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/shared/archivelogs'
STANDBY_FILE_MANAGEMENT=AUTO
FAL_SERVER='ORCL'
FAL_CLIENT='STBY'
DB_FILE_NAME_CONVERT='/ORCL/','/STBY/'
LOG_FILE_NAME_CONVERT='/ORCL/','/STBY/'
```

#### C. Comandos Útiles

```powershell
# Docker
docker-compose up -d                    # Iniciar servicios
docker-compose down                     # Detener servicios
docker exec -it oracle_primary bash     # Conectar a primaria
docker logs oracle_primary             # Ver logs primaria

# Oracle
sqlplus sys/admin123@ORCL as sysdba    # Conectar primaria
sqlplus sys/admin123@STBY as sysdba    # Conectar standby
ALTER SYSTEM SWITCH LOGFILE;           # Forzar log switch
ALTER SYSTEM ARCHIVE LOG CURRENT;      # Archivar log actual

# Automatización
.\dataguard_complete.ps1 -Action status     # Ver estado
.\profesor_demo.ps1                           # Demo completa
.\task_scheduler_complete.ps1 -Operation install       # Instalar tareas
```

---

**Autor**: Equipo de Desarrollo ACS  
**Fecha**: Octubre 2025  
**Versión**: 1.0  
**Revisión**: Funcional y Completa
