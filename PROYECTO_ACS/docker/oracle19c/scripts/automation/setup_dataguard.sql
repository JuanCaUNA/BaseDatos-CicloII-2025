-- ========================================
-- SCRIPT COMPLETO DE CONFIGURACIÓN DATA GUARD
-- Debe ejecutarse DESPUÉS de que ambos contenedores estén funcionando
-- ========================================

-- =========================================
-- PASO 1: CONFIGURAR BASE DE DATOS PRIMARIA
-- =========================================

CONNECT sys/admin123@oracle-primary:1521/ORCL as sysdba

-- Verificar estado actual
SELECT name, log_mode, force_logging, database_role FROM v$database;

-- Si no está en ARCHIVELOG, configurarlo
DECLARE
  v_log_mode VARCHAR2(20);
BEGIN
  SELECT log_mode INTO v_log_mode FROM v$database;
  IF v_log_mode != 'ARCHIVELOG' THEN
    EXECUTE IMMEDIATE 'SHUTDOWN IMMEDIATE';
    EXECUTE IMMEDIATE 'STARTUP MOUNT';
    EXECUTE IMMEDIATE 'ALTER DATABASE ARCHIVELOG';
    EXECUTE IMMEDIATE 'ALTER DATABASE OPEN';
  END IF;
END;
/

-- Crear control file para standby
ALTER DATABASE CREATE STANDBY CONTROLFILE AS '/opt/oracle/shared/standby_controlfile.ctl';

-- Crear backup para standby database
-- (Este paso normalmente se haría con RMAN, aquí simplificado)

-- =============================================
-- PASO 2: CONFIGURAR BASE DE DATOS STANDBY
-- =============================================

-- Conectar al standby y preparar
CONNECT sys/admin123@oracle-standby:1521/STBY as sysdba

-- Shutdown y startup nomount
SHUTDOWN IMMEDIATE;
STARTUP NOMOUNT;

-- Copiar el control file (esto normalmente se hace a nivel de OS)
-- host cp /opt/oracle/shared/standby_controlfile.ctl /opt/oracle/oradata/STBY/control01.ctl

-- Montar la base de datos standby
-- ALTER DATABASE MOUNT STANDBY DATABASE;

-- Iniciar recuperación administrada
-- ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;

-- ===========================================
-- PASO 3: VERIFICACIONES
-- ===========================================

CONNECT sys/admin123@oracle-primary:1521/ORCL as sysdba

-- Verificar configuración primaria
SELECT dest_name, status, destination FROM v$archive_dest WHERE dest_name IN ('LOG_ARCHIVE_DEST_1','LOG_ARCHIVE_DEST_2');

-- Forzar log switch para probar
ALTER SYSTEM SWITCH LOGFILE;

-- Verificar generación de archivelogs
SELECT name, completion_time FROM v$archived_log WHERE completion_time > SYSDATE - 1/24 ORDER BY completion_time DESC;

EXIT;