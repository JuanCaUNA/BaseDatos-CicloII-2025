-- ===============================================================================
-- ORACLE DATA GUARD - CONFIGURACIÓN PRIMARY CON RMAN
-- Base de datos: ORCL (Primary)
-- Propósito: Preparar Primary para duplicación activa (RMAN DUPLICATE FROM ACTIVE DATABASE)
-- ===============================================================================

SET TERMOUT ON
SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 200
SET LINESIZE 200
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

SPOOL /opt/oracle/shared/primary_config.log

HOST rm -f /opt/oracle/shared/state/primary_ready.ok

PROMPT =============================================================================== 
PROMPT ORACLE DATA GUARD - CONFIGURACIÓN PRIMARY CON RMAN
PROMPT Preparando la base de datos ORCL para duplicación activa
PROMPT =============================================================================== 

-- Paso 0. Validar prerequisitos locales (password file, red, listener)
HOST bash /opt/oracle/scripts/setup/helpers/ensure_password_file.sh
HOST bash /opt/oracle/scripts/setup/helpers/create_tnsnames.sh
HOST bash /opt/oracle/scripts/setup/helpers/ensure_listener.sh

-- Paso 1. Detener instancia previa si está activa
SHUTDOWN IMMEDIATE;

-- Paso 2. Iniciar en modo MOUNT
STARTUP MOUNT;

-- Paso 3. Activar ARCHIVELOG y FORCE LOGGING
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE FORCE LOGGING;

-- Paso 4. Configurar parámetros de Data Guard
ALTER SYSTEM SET DB_UNIQUE_NAME='ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,STBY)' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/shared/archivelogs VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=ORCL' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=STBY LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=STBY' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=DEFER SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='arch_%t_%s_%r.arc' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=5 SCOPE=SPFILE;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=SPFILE;
ALTER SYSTEM SET FAL_SERVER='STBY' SCOPE=SPFILE;
ALTER SYSTEM SET FAL_CLIENT='ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET DB_FILE_NAME_CONVERT='/opt/oracle/oradata/STBY/','/opt/oracle/oradata/ORCL/' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_FILE_NAME_CONVERT='/opt/oracle/oradata/STBY/','/opt/oracle/oradata/ORCL/' SCOPE=SPFILE;
ALTER SYSTEM SET DG_BROKER_START=TRUE SCOPE=BOTH;
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE='EXCLUSIVE' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_BUFFER=33554432 SCOPE=SPFILE;
ALTER SYSTEM SET SERVICE_NAMES='ORCL' SCOPE=BOTH;
ALTER SYSTEM SET INSTANCE_NAME='ORCL' SCOPE=SPFILE;

-- Paso 5. Crear directorios
HOST mkdir -p /opt/oracle/shared/archivelogs /opt/oracle/shared/backups /opt/oracle/shared/state /opt/oracle/shared/logs
HOST chown -R oracle:oinstall /opt/oracle/shared/archivelogs /opt/oracle/shared/backups /opt/oracle/shared/state /opt/oracle/shared/logs
HOST chmod -R 750 /opt/oracle/shared/archivelogs /opt/oracle/shared/backups /opt/oracle/shared/state /opt/oracle/shared/logs

-- Paso 6. Abrir base de datos
ALTER DATABASE OPEN;

-- Paso 7. Ajustar grupos de redo y standby redo logs con tamaños consistentes
DECLARE
	l_max_mb        PLS_INTEGER;
	l_log_count     PLS_INTEGER;
	l_target_logs   PLS_INTEGER;
	l_target_srl    PLS_INTEGER;
	l_filename      VARCHAR2(512);
BEGIN
	SELECT CEIL(MAX(bytes) / 1024 / 1024), COUNT(*)
		INTO l_max_mb, l_log_count
		FROM v$log;

	l_target_logs := GREATEST(l_log_count, 4);

	WHILE l_log_count < l_target_logs LOOP
		l_filename := '/opt/oracle/oradata/ORCL/redo' || LPAD(l_log_count + 1, 2, '0') || '.log';
		BEGIN
			EXECUTE IMMEDIATE 'ALTER DATABASE ADD LOGFILE GROUP ' || (l_log_count + 1) ||
				' ''' || l_filename || ''' SIZE ' || l_max_mb || 'M';
			DBMS_OUTPUT.PUT_LINE('Redo log group ' || (l_log_count + 1) || ' creado (' || l_max_mb || ' MB).');
			l_log_count := l_log_count + 1;
		EXCEPTION
			WHEN OTHERS THEN
				IF SQLERRM LIKE '%already%' OR SQLERRM LIKE '%exist%' THEN
					DBMS_OUTPUT.PUT_LINE('Redo log group ' || (l_log_count + 1) || ' ya presente.');
					l_log_count := l_log_count + 1;
				ELSE
					RAISE;
				END IF;
		END;
	END LOOP;

	FOR rec IN (SELECT DISTINCT group# FROM v$standby_log) LOOP
		BEGIN
			EXECUTE IMMEDIATE 'ALTER DATABASE DROP STANDBY LOGFILE GROUP ' || rec.group#;
			DBMS_OUTPUT.PUT_LINE('Standby redo log group ' || rec.group# || ' eliminado.');
		EXCEPTION
			WHEN OTHERS THEN
				IF SQLERRM LIKE '%does not exist%' THEN
					DBMS_OUTPUT.PUT_LINE('Standby redo log group ' || rec.group# || ' ya no existe.');
				ELSE
					RAISE;
				END IF;
		END;
	END LOOP;
END;
/

HOST rm -f /opt/oracle/oradata/ORCL/standby_redo*.log 2>/dev/null || true

-- Paso 8. Crear standby redo logs dimensionados para LGWR/real-time apply
DECLARE
	l_max_mb     PLS_INTEGER;
	l_log_count  PLS_INTEGER;
	l_target_srl PLS_INTEGER;
	l_filename   VARCHAR2(512);
BEGIN
	SELECT CEIL(MAX(bytes) / 1024 / 1024), COUNT(*)
		INTO l_max_mb, l_log_count
		FROM v$log;

	l_target_srl := l_log_count + 1;

	FOR idx IN 1 .. l_target_srl LOOP
		l_filename := '/opt/oracle/oradata/ORCL/standby_redo' || LPAD(idx, 2, '0') || '.log';
		BEGIN
			EXECUTE IMMEDIATE 'ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 ''' || l_filename || ''' SIZE ' || l_max_mb || 'M';
			DBMS_OUTPUT.PUT_LINE('Standby redo log ' || l_filename || ' creado (' || l_max_mb || ' MB).');
		EXCEPTION
			WHEN OTHERS THEN
				IF SQLERRM LIKE '%already%' OR SQLERRM LIKE '%exist%' THEN
					DBMS_OUTPUT.PUT_LINE('Standby redo log ' || l_filename || ' ya presente.');
				ELSE
					RAISE;
				END IF;
		END;
	END LOOP;
END;
/

-- Paso 9. Generar archive logs iniciales
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM SWITCH LOGFILE;

-- Paso 10. Crear usuario de aplicación (idempotente)
ALTER SESSION SET CONTAINER = ORCLPDB1;
DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_exists FROM dba_users WHERE username = 'ACS_ADMIN';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'CREATE USER acs_admin IDENTIFIED BY acs_admin';
	END IF;
	EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, DBA TO acs_admin';
END;
/
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Paso 11. Validación
SELECT name, log_mode, force_logging, database_role FROM v$database;
SELECT dest_name, status, destination FROM v$archive_dest WHERE dest_name IN ('LOG_ARCHIVE_DEST_1','LOG_ARCHIVE_DEST_2');
SELECT group#, thread#, bytes/1024/1024 AS size_mb, members, status FROM v$log ORDER BY group#;
SELECT group#, thread#, bytes/1024/1024 AS size_mb FROM v$standby_log ORDER BY group#;

PROMPT =============================================================================== 
PROMPT PRIMARY CONFIGURADO EXITOSAMENTE
PROMPT RMAN puede ahora duplicar esta base al Standby.
PROMPT LOG_ARCHIVE_DEST_2 está en DEFER (se activará tras RMAN DUPLICATE)
PROMPT =============================================================================== 

SELECT 'Finalización: ' || TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS timestamp FROM dual;

HOST touch /opt/oracle/shared/state/primary_ready.ok

SPOOL OFF
EXIT;
