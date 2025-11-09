-- ========================================
-- SCRIPT DE INICIALIZACIÓN STANDBY
-- Base de datos: STBY (Standby)
-- Propósito: Configurar Data Guard Standby
-- ========================================
-- GUÍA PARA QUIEN NO ESPECIALISTA:
-- * Este archivo se ejecuta automáticamente dentro del contenedor "oracle_standby".
-- * Solo observa los mensajes "PROMPT"; indican claramente qué se está haciendo.
-- * Si aparece "WARNING" significa que falta copiar el controlfile desde el primario.
-- * Ante cualquier error el contenedor se detiene y el detalle queda en /opt/oracle/shared/standby_config.log.
-- * Para confirmar éxito busca el mensaje final "FINAL DEL SCRIPT DEL STANDBY (correcto)".

-- Configuración de SQL*Plus para mostrar cada paso y abortar ante el primer error.

SET TERMOUT ON;
SET ECHO ON;
SET FEEDBACK ON;
SET VERIFY OFF;
SET PAGESIZE 200;
SET LINESIZE 200;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
-- El log detallado queda en el directorio compartido para revisarlo cuando sea necesario.

SPOOL /opt/oracle/shared/standby_config.log
PROMPT === INICIO DEL SCRIPT DEL STANDBY ===
SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS start_time FROM dual;

PROMPT [STANDBY][Paso 1/10] Apagando la instancia si quedó encendida...
-- Detener la base de datos si está iniciada
SHUTDOWN IMMEDIATE;

PROMPT [STANDBY][Paso 2/10] Iniciando en modo NOMOUNT para permitir cambios...
-- Configurar parámetros para Standby
-- Nota: Estos comandos requieren que el spfile exista
STARTUP NOMOUNT;

PROMPT [STANDBY][Paso 3/10] Ajustando los parámetros que conectan con el primario...
-- Configurar parámetros específicos para Standby
ALTER SYSTEM SET DB_UNIQUE_NAME='STBY' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,STBY)' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/shared/archivelogs VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=STBY' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=ORCL LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=DEFER SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='arch_%t_%s_%r.arc' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=5 SCOPE=SPFILE;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=SPFILE;
ALTER SYSTEM SET FAL_SERVER='ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET FAL_CLIENT='STBY' SCOPE=SPFILE;

-- Definir la ubicación de los controlfiles del Standby
PROMPT [STANDBY][Paso 4/10] Definiendo dónde se guardarán los controlfiles del Standby...
ALTER SYSTEM SET CONTROL_FILES='/opt/oracle/oradata/STBY/control01.ctl','/opt/oracle/oradata/STBY/control02.ctl' SCOPE=SPFILE;

-- Configuraciones específicas para Standby
PROMPT [STANDBY][Paso 5/10] Configurando rutas de datafiles y redologs para este servidor...
ALTER SYSTEM SET DB_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/STBY/' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/STBY/' SCOPE=SPFILE;

PROMPT [STANDBY][Paso 6/10] Reiniciando para aplicar las configuraciones...
-- Reiniciar para aplicar cambios
SHUTDOWN IMMEDIATE;

PROMPT [STANDBY][Paso 7/10] Copiando el controlfile generado por el primario (indispensable)...
-- Copiar el controlfile generado por el primario si está disponible
HOST /bin/bash -c "CONTROLFILE_SRC=/opt/oracle/shared/standby_controlfile.ctl; CONTROLFILE_DEST=/opt/oracle/oradata/STBY; if [ -f \"$CONTROLFILE_SRC\" ]; then mkdir -p \"$CONTROLFILE_DEST\"; cp \"$CONTROLFILE_SRC\" \"$CONTROLFILE_DEST/control01.ctl\"; cp \"$CONTROLFILE_SRC\" \"$CONTROLFILE_DEST/control02.ctl\"; chmod 640 \"$CONTROLFILE_DEST\"/control0*.ctl; else echo 'WARNING: Standby controlfile not found at /opt/oracle/shared/standby_controlfile.ctl' >&2; fi"

PROMPT [STANDBY][Paso 8/10] Iniciando nuevamente en NOMOUNT con el controlfile listo...
STARTUP NOMOUNT;

PROMPT [STANDBY][Paso 9/10] Montando la base como Standby y abriéndola en solo lectura...
-- Montar la base de datos en modo standby
ALTER DATABASE MOUNT STANDBY DATABASE;

-- Abrir en modo solo lectura para permitir healthchecks sencillos
ALTER DATABASE OPEN READ ONLY;

PROMPT [STANDBY][Paso 10/10] Iniciando la recuperación automática en tiempo real...
-- Iniciar la recuperación en tiempo real
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;

-- Se asume que el primario generó el controlfile en /opt/oracle/shared y pudo copiarse
PROMPT [STANDBY] Resumen final para verificar el estado actual:
SELECT name FROM v$controlfile;
SELECT open_mode, database_role, protection_mode FROM v$database;

PROMPT === FINAL DEL SCRIPT DEL STANDBY (correcto) ===
SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS end_time FROM dual;
SELECT 'Standby database montada, abierta en READ ONLY y recuperación en tiempo real activa.' AS status FROM dual;
SPOOL OFF

EXIT;
