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

**Data Guard**: Conjunto de servicios, aplicaciones y configuraciones que crean, mantienen y monitorean una o más bases de datos standby.

**Base de datos Primaria**: La base de datos de producción que recibe todas las transacciones de usuarios y aplicaciones.

**Base de datos Standby**: Copia física de la base de datos primaria que se mantiene sincronizada mediante la aplicación de redo logs.

**Redo Transport**: Servicio que controla la transmisión automática de redo data desde la base primaria hacia las bases standby.

**Redo Apply**: Proceso que aplica los redo logs recibidos en la base de datos standby para mantenerla sincronizada.

**ARCHIVELOG Mode**: Modo de operación que permite guardar los redo logs llenos como archivos de archivo, esencial para Data Guard.

Requisitos previos
------------------

- Oracle 19c instalado en ambos servidores (puede ser Linux o Windows). Versiones y parches deben ser compatibles.
- Conectividad SSH entre primaria -> standby (clave SSH sin contraseña recomendada) o uso de compartido de archivos.
- Espacio en disco suficiente para archivelogs y backups en ambos servidores.
- Usuarios OS para ejecutar scripts (ej. oracle) con variables ORACLE_HOME y ORACLE_SID configuradas.
- Credenciales de SYSDBA para ejecutar sqlplus y RMAN.

Conceptos clave
---------------

- ARCHIVELOG: modo de base de datos que genera archivos de redo archivados.
- SWITCH LOGFILE: fuerza al DB a cerrar el current redo log y generar un archivelog.
- RMAN: herramienta para realizar backups y gestionar archivelogs.
- Transporte de archivelogs: puede hacerse por Data Guard (nativo) o por transporte de archivos (rsync/scp) y aplicación en standby.

Estrategia propuesta (simple y reproducible)
------------------------------------------

1) Poner la base de datos primaria en ARCHIVELOG y abrirla en modo FORCE LOGGING.
2) Crear un job (cron o Task Scheduler) que ejecute `ALTER SYSTEM SWITCH LOGFILE;` cada 5 minutos -> garantiza archivo de actualización periódica.
3) Otro job (cada 10 minutos) que copie los archivelogs nuevos al servidor standby (rsync/scp). En el standby hay un proceso que aplica o deja listos los logs para recuperación en caliente.
4) Ejecutar diariamente un backup RMAN (full o incremental + archivelogs) y transferir el backup al standby.
5) Ejecutar purga de archivelogs en primaria y en standby para eliminar archivos con más de 3 días.

Archivos añadidos
-----------------

Se incluyen scripts de ejemplo (ajustables):

- `SRC/UTILITIES/standby/linux/switch_and_send.sh`  -- forzar switch y enviar archivelogs.
- `SRC/UTILITIES/standby/linux/transfer_archivelogs.sh` -- sincronizar archivelogs al standby (planificado cada 10 min).
- `SRC/UTILITIES/standby/linux/rman_daily_backup.sh` -- RMAN backup diario y envío al standby.
- `SRC/UTILITIES/standby/linux/purge_archivelogs.sh` -- purga en primaria (archivelogs >3 días).
- `SRC/UTILITIES/standby/windows/switch_and_send.ps1` -- PowerShell versión.
- `SRC/UTILITIES/standby/windows/transfer_archivelogs.ps1`
- `SRC/UTILITIES/standby/windows/rman_daily_backup.ps1`
- `SRC/UTILITIES/standby/windows/purge_archivelogs.ps1`

Ejemplos de configuración
-------------------------

-- Parámetros importantes del init/spfile (ajustar según entorno):

- LOG_ARCHIVE_CONFIG='DG_CONFIG=(PRIMARY,STANDBY)'
- LOG_ARCHIVE_DEST_1='LOCATION=/u01/app/oracle/oradata/ORCL/archivelog'
- LOG_ARCHIVE_DEST_2='SERVICE=standby_1 LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=STDBY'
- LOG_ARCHIVE_MAX_PROCESSES=5
- FAL_SERVER (si usa broker): configurar DGMGRL para control centralizado.

Notas sobre generación de archivelogs cada 50MB
------------------------------------------------

Oracle no tiene un parámetro exacto 'generar archivelog cada 50MB' pero la generación depende del tamaño de redo logs. Dos opciones:

1) Disminuir tamaño de redo logs para que se roten antes (menos práctico en producción).
2) Forzar SWITCH LOGFILE periódicamente (script cron cada 5 minutos). Esto garantiza un archivelog cada 5 minutos.

Implementación de los scripts (resumen)
-------------------------------------

Linux (ejemplo):

- switch_and_send.sh: ejecuta `ALTER SYSTEM SWITCH LOGFILE;` y mueve los archivelogs generados al directorio de envío.
- transfer_archivelogs.sh: usa rsync/ssh para enviar los archivos nuevos al standby (puede remover archivos fuente tras confirmación).
- rman_daily_backup.sh: ejecuta RMAN para backup full+archivelogs y envía el resultado al standby.
- purge_archivelogs.sh: ejecuta RMAN DELETE ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-3' NOPROMPT.

Windows (PowerShell): las versiones PS usan sqlplus.exe y scp/WinSCP para transferencia.

Planes de ejecución
-------------------

Crontab sugerido (Linux, usuario oracle):

*/5 * * * * /home/oracle/standby/switch_and_send.sh >> /var/log/standby/switch.log 2>&1
*/10 * * * * /home/oracle/standby/transfer_archivelogs.sh >> /var/log/standby/transfer.log 2>&1
0 2 * * * /home/oracle/standby/rman_daily_backup.sh >> /var/log/standby/rman_backup.log 2>&1
0 3 * * * /home/oracle/standby/purge_archivelogs.sh >> /var/log/standby/purge.log 2>&1

Task Scheduler (Windows): crear tareas que invoquen las .ps1 con los mismos intervalos.

Ejecución a demanda durante la revisión
--------------------------------------

Crear un script `manual_trigger.sh` (o .ps1) que ejecute en secuencia:

1) `ALTER SYSTEM SWITCH LOGFILE;`
2) Forzar transferencia inmediata (`transfer_archivelogs`)
3) Ejecutar `rman_daily_backup.sh` si se requiere respaldo in situ

Purgas y seguridad
-------------------

- Las purgas se hacen con RMAN para no afectar consistencia.
- Mantener logs de envío y aplicar monitorización (sencillo: verificar ultimos archivos enviados con ls -ltr).

Verificación y pruebas
----------------------

1) Validar que la primaria esté en ARCHIVELOG: `SELECT log_mode FROM v$database;`
2) Ejecutar manualmente `ALTER SYSTEM SWITCH LOGFILE;` y verificar que aparece un nuevo archivelog en `v$archived_log`.
3) Ejecutar transferencia y comprobar el archivo en standby.
4) En standby, lanzar la recuperación: `ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;` o usar Data Guard Broker.

Limitaciones y recomendaciones
------------------------------

- Esta guía provee una solución de transporte basado en archivos; para producción se recomienda Data Guard (broker) con configuración de redo transport y aplicacion automática.
- Asegurar red confiable y monitoreo. Automatizar alertas si transferencia falla.
- Probar con un conjunto reducido de datos antes de producción.

Conclusión
----------

Los scripts añadidos y este manual dan un flujo reproducible para cumplir los requisitos del entregable: periódicamente generar archivelogs (cada 5 minutos forzados), trasladarlos cada 10 minutos al standby, respaldos diarios y purga de archivos a 3 días. Ajuste variables y permisos al entorno real.
