-- ========================================
-- SCRIPT DE INICIALIZACIÓN STANDBY
-- Base de datos: STBY (Standby)
-- Propósito: Configurar Data Guard Standby
-- ========================================

-- Detener la base de datos si está iniciada
SHUTDOWN IMMEDIATE;

-- Configurar parámetros para Standby
-- Nota: Estos comandos requieren que el spfile exista
STARTUP NOMOUNT;

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

-- Configuraciones específicas para Standby
ALTER SYSTEM SET DB_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/STBY/' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/STBY/' SCOPE=SPFILE;

-- Reiniciar para aplicar cambios
SHUTDOWN IMMEDIATE;
STARTUP NOMOUNT;

-- Este punto requiere que se restaure el controlfile desde Primary
-- El proceso completo se hará con RMAN o mediante copia de archivos

SPOOL /opt/oracle/shared/standby_config.log
SELECT 'Standby Database Parameters Configured' AS status FROM dual WHERE 1=0;
-- La consulta anterior no se ejecutará hasta que la DB esté montada
SPOOL OFF

EXIT;
