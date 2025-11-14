-- =====================================================================
-- ORACLE DATA GUARD - STANDBY CONFIGURATION (RMAN DUPLICATE METHOD)
-- =====================================================================
-- Autor: ING. EGRANADOS
-- Descripción:
--   Script SQL ejecutado dentro del contenedor Standby.
--   Prepara entorno, genera SPFILE y deja todo listo para RMAN.
-- =====================================================================

SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 200
SET LINESIZE 200
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Crear directorios
HOST mkdir -p /opt/oracle/shared/logs /opt/oracle/shared/archivelogs
HOST mkdir -p /opt/oracle/oradata/STBY /opt/oracle/admin/STBY/adump
HOST sh -c "chown -R oracle:oinstall /opt/oracle/oradata/STBY /opt/oracle/admin/STBY /opt/oracle/shared 2>/dev/null || echo '[STANDBY][WARN] chown omitido (sin privilegios o volumen compartido)'."
HOST sh -c "chmod -R 775 /opt/oracle/oradata/STBY /opt/oracle/admin/STBY /opt/oracle/shared 2>/dev/null || echo '[STANDBY][WARN] chmod omitido (sin privilegios o volumen compartido)'."

SPOOL /opt/oracle/shared/logs/init_standby.log

PROMPT [STANDBY][Paso 1/8] Validando prerequisitos (password file, red, listener)...
HOST bash /opt/oracle/scripts/setup/helpers/ensure_password_file.sh
HOST bash /opt/oracle/scripts/setup/helpers/create_tnsnames.sh
HOST bash /opt/oracle/scripts/setup/helpers/ensure_listener.sh

PROMPT [STANDBY][Paso 2/8] Creando PFILE temporal...
HOST bash /opt/oracle/scripts/setup/helpers/create_standby_pfile.sh

HOST bash -c "if [[ -f /tmp/init${ORACLE_SID}_temp.ora ]]; then cp /tmp/init${ORACLE_SID}_temp.ora /opt/oracle/product/19c/dbhome_1/dbs/init${ORACLE_SID}.ora; else echo '[STANDBY][INFO] Se conserva init${ORACLE_SID}.ora existente.'; fi"

PROMPT [STANDBY][Paso 3/8] Iniciando instancia en NOMOUNT...
WHENEVER SQLERROR CONTINUE
SHUTDOWN ABORT;
WHENEVER SQLERROR EXIT SQL.SQLCODE
STARTUP NOMOUNT PFILE='/opt/oracle/product/19c/dbhome_1/dbs/initSTBY.ora';

PROMPT [STANDBY][Paso 4/8] Creando SPFILE desde PFILE (reemplazo idempotente)...
HOST bash -c "if [[ -f /opt/oracle/product/19c/dbhome_1/dbs/spfileSTBY.ora ]]; then echo '[STANDBY][INFO] SPFILE existente detectado, se reemplazará.'; rm -f /opt/oracle/product/19c/dbhome_1/dbs/spfileSTBY.ora; fi"
CREATE SPFILE='/opt/oracle/product/19c/dbhome_1/dbs/spfileSTBY.ora' FROM PFILE='/opt/oracle/product/19c/dbhome_1/dbs/initSTBY.ora';

PROMPT [STANDBY][Paso 5/8] Configurando parámetros Data Guard...
WHENEVER SQLERROR CONTINUE
SHUTDOWN ABORT;
WHENEVER SQLERROR EXIT SQL.SQLCODE
STARTUP NOMOUNT;

ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=SPFILE;
ALTER SYSTEM SET FAL_SERVER='ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET FAL_CLIENT='STBY' SCOPE=SPFILE;
ALTER SYSTEM SET DB_UNIQUE_NAME='STBY' SCOPE=SPFILE;
ALTER SYSTEM SET ENABLE_PLUGGABLE_DATABASE=TRUE SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,STBY)' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/shared/archivelogs VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=STBY' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=ORCL LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=DEFER SCOPE=SPFILE;
ALTER SYSTEM SET SERVICE_NAMES='STBY' SCOPE=SPFILE;
ALTER SYSTEM SET INSTANCE_NAME='STBY' SCOPE=SPFILE;
ALTER SYSTEM SET DB_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/STBY/' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_FILE_NAME_CONVERT='/opt/oracle/oradata/ORCL/','/opt/oracle/oradata/STBY/' SCOPE=SPFILE;
ALTER SYSTEM SET CONTROL_FILES='/opt/oracle/oradata/STBY/control01.ctl','/opt/oracle/oradata/STBY/control02.ctl' SCOPE=SPFILE;

PROMPT [STANDBY][Paso 6/8] Reiniciando con SPFILE actualizado...
WHENEVER SQLERROR CONTINUE
SHUTDOWN ABORT;
WHENEVER SQLERROR EXIT SQL.SQLCODE
STARTUP NOMOUNT;

PROMPT [STANDBY][Paso 7/8] Ejecutando RMAN (fuera de SQL)...
HOST bash -c "/opt/oracle/scripts/setup/helpers/run_duplicate_rman.sh"
 
PROMPT [STANDBY][Paso 8/8] Validando estado...
SELECT name, db_unique_name, database_role, open_mode FROM v$database;
SELECT process, status, thread#, sequence#, block#, blocks FROM v$managed_standby WHERE process LIKE 'MRP%' OR process LIKE 'RFS%';

HOST bash /opt/oracle/scripts/setup/helpers/verify_init_log.sh

SPOOL OFF
EXIT;
