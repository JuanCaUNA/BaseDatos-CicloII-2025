-- ========================================
-- SCRIPT DE INICIALIZACIÓN PRIMARIA
-- Base de datos: ORCL (Primary)
-- Propósito: Configurar Data Guard
-- ========================================
-- GUÍA PARA QUIEN NO ESPECIALISTA:
-- * Este script se ejecuta solo cuando el contenedor "oracle_primary" inicia.
-- * No necesitas ejecutar comandos manuales; solo revisa los mensajes que aparecen.
-- * Cada "PROMPT" describe en español simple qué está ocurriendo.
-- * Si algo falla, el contenedor se detiene y el mensaje de error queda en /opt/oracle/shared/primary_config.log.
-- * Al final debe verse "FINAL DEL SCRIPT DEL PRIMARIO (todo listo)". Si no aparece, revisa el log mencionado.

-- Configuración de SQL*Plus para mostrar todo y detenerse si ocurre algún error.
SET TERMOUT ON;
SET ECHO ON;
SET FEEDBACK ON;
SET VERIFY OFF;
SET PAGESIZE 200;
SET LINESIZE 200;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Guardamos un registro legible en el área compartida para consultas posteriores.
SPOOL /opt/oracle/shared/primary_config.log
PROMPT === INICIO DEL SCRIPT DEL PRIMARIO ===
SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS start_time FROM dual;

PROMPT [PRIMARY][Paso 1/11] Deteniendo cualquier instancia previa...
SHUTDOWN IMMEDIATE;

PROMPT [PRIMARY][Paso 2/11] Iniciando la base en modo especial para configuración...
STARTUP MOUNT;

PROMPT [PRIMARY][Paso 3/11] Activando los modos necesarios para Data Guard (ARCHIVELOG y FORCE LOGGING)...
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE FORCE LOGGING;

PROMPT [PRIMARY][Paso 4/11] Ajustando parámetros que permiten enviar información al Standby...
ALTER SYSTEM SET DB_UNIQUE_NAME='ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,STBY)' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/shared/archivelogs VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=ORCL' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=STBY LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=STBY' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=DEFER SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='arch_%t_%s_%r.arc' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=5 SCOPE=SPFILE;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=SPFILE;
ALTER SYSTEM SET FAL_SERVER='STBY' SCOPE=SPFILE;
ALTER SYSTEM SET FAL_CLIENT='ORCL' SCOPE=SPFILE;
-- Ajuste del tamaño del buffer de redo logs para mejorar el envío.
ALTER SYSTEM SET LOG_BUFFER=33554432 SCOPE=SPFILE;

PROMPT [PRIMARY][Paso 5/11] Abriendo la base para uso normal tras la configuración...
ALTER DATABASE OPEN;

PROMPT [PRIMARY][Paso 6/11] Añadiendo grupos de redo logs para soportar mayor carga...
ALTER DATABASE ADD LOGFILE GROUP 4 '/opt/oracle/oradata/ORCL/redo04.log' SIZE 100M;
ALTER DATABASE ADD LOGFILE GROUP 5 '/opt/oracle/oradata/ORCL/redo05.log' SIZE 100M;
ALTER DATABASE ADD LOGFILE GROUP 6 '/opt/oracle/oradata/ORCL/redo06.log' SIZE 100M;

PROMPT [PRIMARY][Paso 7/11] Creando archivos especiales para que el Standby reciba cambios en vivo...
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 '/opt/oracle/oradata/ORCL/standby_redo01.log' SIZE 100M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 '/opt/oracle/oradata/ORCL/standby_redo02.log' SIZE 100M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 '/opt/oracle/oradata/ORCL/standby_redo03.log' SIZE 100M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 '/opt/oracle/oradata/ORCL/standby_redo04.log' SIZE 100M;

PROMPT [PRIMARY][Paso 8/11] Generando archivos históricos iniciales (log switches)...
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM SWITCH LOGFILE;

PROMPT [PRIMARY][Paso 9/11] Creando el usuario administrador "acs_admin" para la aplicación...
ALTER SESSION SET CONTAINER = ORCLPDB1;
CREATE USER acs_admin IDENTIFIED BY acs_admin;
GRANT CONNECT, RESOURCE, DBA TO acs_admin;
ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT [PRIMARY][Paso 10/11] Revisando que los parámetros quedaron activos...
SELECT name, log_mode, force_logging FROM v$database;
SELECT dest_name, status, destination FROM v$archive_dest WHERE dest_name IN ('LOG_ARCHIVE_DEST_1','LOG_ARCHIVE_DEST_2');

PROMPT [PRIMARY][Paso 11/11] Creando el archivo que necesita el Standby para arrancar...
ALTER DATABASE CREATE STANDBY CONTROLFILE AS '/opt/oracle/shared/standby_controlfile.ctl';

PROMPT [PRIMARY] Activando el envío de información al servidor Standby...
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE SCOPE=BOTH;

PROMPT [PRIMARY] Resumen final (archivos de control y destinos de envío):
SELECT name FROM v$controlfile;
SELECT dest_name, status, error FROM v$archive_dest_status WHERE dest_name IN ('LOG_ARCHIVE_DEST_1','LOG_ARCHIVE_DEST_2');

PROMPT === FINAL DEL SCRIPT DEL PRIMARIO (todo listo) ===
SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS end_time FROM dual;
SELECT 'Configuración del primario terminada. El controlfile para el Standby está en /opt/oracle/shared/standby_controlfile.ctl' AS status FROM dual;
SPOOL OFF

EXIT;
