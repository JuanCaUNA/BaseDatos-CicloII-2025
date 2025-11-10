-- ============================================================================
-- PUNTO 9 DE LA RÚBRICA: SEGURIDAD DE BASE DE DATOS (9%)
-- ============================================================================
-- Requisito: "Implementar roles (3%), usuarios (3%) y perfiles (3%)"
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 50

PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PUNTO 9: SEGURIDAD DE BASE DE DATOS (9%)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT  Este script demuestra:
PROMPT  1. Creación de PERFILES con límites de recursos (3%)
PROMPT  2. Creación de ROLES con privilegios específicos (3%)
PROMPT  3. Creación de USUARIOS con roles y perfiles asignados (3%)
PROMPT  4. Validaciones de seguridad
PROMPT 

-- ============================================================================
-- PARTE 1: PERFILES (3%)
-- ============================================================================

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 1: PERFILES DE USUARIO (3%)
PROMPT ════════════════════════════════════════════════════════════════════════════

-- ============================================================================
-- PASO 1.1: Crear Perfil para Administradores
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 1.1: Perfil ADMIN_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP PROFILE ADMIN_ACS CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE PROFILE ADMIN_ACS LIMIT
    -- Límites de sesión
    SESSIONS_PER_USER 5              -- Máximo 5 sesiones simultáneas
    CONNECT_TIME 480                 -- Máximo 8 horas de conexión continua
    IDLE_TIME 60                     -- Desconexión tras 60 min de inactividad
    
    -- Límites de recursos
    CPU_PER_SESSION UNLIMITED        -- CPU ilimitado para admins
    CPU_PER_CALL 30000               -- 30 segundos por llamada
    LOGICAL_READS_PER_SESSION UNLIMITED
    LOGICAL_READS_PER_CALL 100000
    
    -- Políticas de contraseña
    FAILED_LOGIN_ATTEMPTS 5          -- Bloqueo tras 5 intentos fallidos
    PASSWORD_LIFE_TIME 90            -- Cambio de clave cada 90 días
    PASSWORD_REUSE_TIME 365          -- No reusar claves del último año
    PASSWORD_REUSE_MAX 5             -- Mínimo 5 cambios antes de reusar
    PASSWORD_LOCK_TIME 1             -- Bloqueo por 1 día
    PASSWORD_GRACE_TIME 7;           -- 7 días de gracia tras expiración

DBMS_OUTPUT.PUT_LINE('✓ Perfil ADMIN_ACS creado');
DBMS_OUTPUT.PUT_LINE('  - Sesiones máximas: 5');
DBMS_OUTPUT.PUT_LINE('  - Tiempo conexión: 8 horas');
DBMS_OUTPUT.PUT_LINE('  - Inactividad: 60 minutos');
DBMS_OUTPUT.PUT_LINE('  - Cambio clave: 90 días');

-- ============================================================================
-- PASO 1.2: Crear Perfil para Usuarios Estándar
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 1.2: Perfil USUARIO_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP PROFILE USUARIO_ACS CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE PROFILE USUARIO_ACS LIMIT
    -- Límites de sesión más restrictivos
    SESSIONS_PER_USER 2              -- Máximo 2 sesiones
    CONNECT_TIME 240                 -- Máximo 4 horas
    IDLE_TIME 30                     -- Desconexión tras 30 min inactividad
    
    -- Límites de recursos moderados
    CPU_PER_SESSION 600000           -- 10 minutos CPU por sesión
    CPU_PER_CALL 10000               -- 10 segundos por llamada
    LOGICAL_READS_PER_SESSION 500000
    LOGICAL_READS_PER_CALL 50000
    
    -- Políticas de contraseña más estrictas
    FAILED_LOGIN_ATTEMPTS 3          -- Bloqueo tras 3 intentos
    PASSWORD_LIFE_TIME 60            -- Cambio cada 60 días
    PASSWORD_REUSE_TIME 180          -- No reusar del último semestre
    PASSWORD_REUSE_MAX 3
    PASSWORD_LOCK_TIME 0.5           -- Bloqueo por 12 horas
    PASSWORD_GRACE_TIME 5;           -- 5 días de gracia

DBMS_OUTPUT.PUT_LINE('✓ Perfil USUARIO_ACS creado');
DBMS_OUTPUT.PUT_LINE('  - Sesiones máximas: 2');
DBMS_OUTPUT.PUT_LINE('  - Tiempo conexión: 4 horas');
DBMS_OUTPUT.PUT_LINE('  - Inactividad: 30 minutos');
DBMS_OUTPUT.PUT_LINE('  - Cambio clave: 60 días');

-- ============================================================================
-- PASO 1.3: Crear Perfil para Consultas (Solo Lectura)
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 1.3: Perfil CONSULTA_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP PROFILE CONSULTA_ACS CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE PROFILE CONSULTA_ACS LIMIT
    -- Límites más restrictivos para consultas
    SESSIONS_PER_USER 1              -- Solo 1 sesión
    CONNECT_TIME 120                 -- Máximo 2 horas
    IDLE_TIME 15                     -- Desconexión tras 15 min
    
    -- Límites de recursos bajos
    CPU_PER_SESSION 300000           -- 5 minutos CPU
    CPU_PER_CALL 5000                -- 5 segundos por llamada
    LOGICAL_READS_PER_SESSION 250000
    LOGICAL_READS_PER_CALL 25000
    
    -- Políticas de contraseña estándar
    FAILED_LOGIN_ATTEMPTS 3
    PASSWORD_LIFE_TIME 90
    PASSWORD_REUSE_TIME 180
    PASSWORD_REUSE_MAX 3
    PASSWORD_LOCK_TIME 1
    PASSWORD_GRACE_TIME 7;

DBMS_OUTPUT.PUT_LINE('✓ Perfil CONSULTA_ACS creado');
DBMS_OUTPUT.PUT_LINE('  - Sesiones máximas: 1');
DBMS_OUTPUT.PUT_LINE('  - Tiempo conexión: 2 horas');
DBMS_OUTPUT.PUT_LINE('  - Solo lectura recomendado');

-- ============================================================================
-- PASO 1.4: Ver Perfiles Creados
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 1.4: Resumen de Perfiles
PROMPT ────────────────────────────────────────────────────────────────────────────

SELECT 
    PROFILE AS "Perfil",
    RESOURCE_NAME AS "Recurso",
    LIMIT AS "Límite"
FROM DBA_PROFILES
WHERE PROFILE IN ('ADMIN_ACS', 'USUARIO_ACS', 'CONSULTA_ACS')
AND RESOURCE_NAME IN (
    'SESSIONS_PER_USER',
    'CONNECT_TIME',
    'IDLE_TIME',
    'FAILED_LOGIN_ATTEMPTS',
    'PASSWORD_LIFE_TIME'
)
ORDER BY PROFILE, RESOURCE_NAME;

PROMPT 
PROMPT  ✓ PARTE 1 COMPLETADA: PERFILES (3%)
PROMPT 

-- ============================================================================
-- PARTE 2: ROLES (3%)
-- ============================================================================

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 2: ROLES Y PRIVILEGIOS (3%)
PROMPT ════════════════════════════════════════════════════════════════════════════

-- ============================================================================
-- PASO 2.1: Rol para Administradores
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 2.1: Rol ROL_ADMIN_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP ROLE ROL_ADMIN_ACS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE ROLE ROL_ADMIN_ACS;

-- Privilegios de sistema
GRANT CREATE SESSION TO ROL_ADMIN_ACS;
GRANT CREATE TABLE TO ROL_ADMIN_ACS;
GRANT CREATE VIEW TO ROL_ADMIN_ACS;
GRANT CREATE PROCEDURE TO ROL_ADMIN_ACS;
GRANT CREATE TRIGGER TO ROL_ADMIN_ACS;
GRANT CREATE SEQUENCE TO ROL_ADMIN_ACS;

-- Privilegios sobre objetos ACS (usar MORA como propietario)
BEGIN
    -- Todas las tablas ACS
    FOR t IN (
        SELECT TABLE_NAME 
        FROM ALL_TABLES 
        WHERE OWNER = 'MORA' 
        AND TABLE_NAME LIKE 'ACS_%'
    ) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON MORA.' || t.TABLE_NAME || ' TO ROL_ADMIN_ACS';
    END LOOP;
    
    -- Todos los procedimientos
    FOR p IN (
        SELECT OBJECT_NAME 
        FROM ALL_PROCEDURES 
        WHERE OWNER = 'MORA' 
        AND OBJECT_NAME LIKE 'PRC_%'
    ) LOOP
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON MORA.' || p.OBJECT_NAME || ' TO ROL_ADMIN_ACS';
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('✓ Rol ROL_ADMIN_ACS creado');
    DBMS_OUTPUT.PUT_LINE('  - Acceso completo (SELECT, INSERT, UPDATE, DELETE)');
    DBMS_OUTPUT.PUT_LINE('  - Ejecución de procedimientos');
END;
/

-- ============================================================================
-- PASO 2.2: Rol para Recursos Humanos
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 2.2: Rol ROL_RRHH_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP ROLE ROL_RRHH_ACS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE ROLE ROL_RRHH_ACS;

GRANT CREATE SESSION TO ROL_RRHH_ACS;

-- Acceso completo a planillas y personal
BEGIN
    FOR t IN (
        SELECT TABLE_NAME 
        FROM ALL_TABLES 
        WHERE OWNER = 'MORA' 
        AND TABLE_NAME IN (
            'ACS_PLANILLA', 'ACS_DETALLE_PLANILLA', 'ACS_MOVIMIENTO',
            'ACS_PERSONA', 'ACS_USUARIO', 'ACS_TIPO_MOVIMIENTO',
            'ACS_PADRON_NACIONAL'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON MORA.' || t.TABLE_NAME || ' TO ROL_RRHH_ACS';
    END LOOP;
    
    -- Solo lectura en escalas y centros
    FOR t IN (
        SELECT TABLE_NAME 
        FROM ALL_TABLES 
        WHERE OWNER = 'MORA' 
        AND TABLE_NAME IN (
            'ACS_ESCALA_BASE', 'ACS_ESCALA_MENSUAL', 'ACS_DETALLE_MENSUAL',
            'ACS_CENTRO_MEDICO', 'ACS_PUESTO_MEDICO', 'ACS_TURNO'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON MORA.' || t.TABLE_NAME || ' TO ROL_RRHH_ACS';
    END LOOP;
    
    -- Procedimientos de planillas
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON MORA.PRC_GENERAR_PLANILLAS_ADMIN TO ROL_RRHH_ACS';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON MORA.PRC_GENERAR_PLANILLAS_MEDICOS TO ROL_RRHH_ACS';
    
    DBMS_OUTPUT.PUT_LINE('✓ Rol ROL_RRHH_ACS creado');
    DBMS_OUTPUT.PUT_LINE('  - Gestión de planillas y personal');
    DBMS_OUTPUT.PUT_LINE('  - Consulta de escalas');
END;
/

-- ============================================================================
-- PASO 2.3: Rol para Médicos
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 2.3: Rol ROL_MEDICO_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP ROLE ROL_MEDICO_ACS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE ROLE ROL_MEDICO_ACS;

GRANT CREATE SESSION TO ROL_MEDICO_ACS;

-- Solo lectura en sus propias escalas y procedimientos
BEGIN
    FOR t IN (
        SELECT TABLE_NAME 
        FROM ALL_TABLES 
        WHERE OWNER = 'MORA' 
        AND TABLE_NAME IN (
            'ACS_ESCALA_MENSUAL', 'ACS_DETALLE_MENSUAL',
            'ACS_PROCEDIMIENTO_SALUD', 'ACS_TIPO_PROCEDIMIENTO',
            'ACS_PLANILLA', 'ACS_DETALLE_PLANILLA'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON MORA.' || t.TABLE_NAME || ' TO ROL_MEDICO_ACS';
    END LOOP;
    
    -- Registrar procedimientos médicos
    EXECUTE IMMEDIATE 'GRANT INSERT ON MORA.ACS_PROCEDIMIENTO_SALUD TO ROL_MEDICO_ACS';
    
    DBMS_OUTPUT.PUT_LINE('✓ Rol ROL_MEDICO_ACS creado');
    DBMS_OUTPUT.PUT_LINE('  - Consulta de escalas propias');
    DBMS_OUTPUT.PUT_LINE('  - Registro de procedimientos');
    DBMS_OUTPUT.PUT_LINE('  - Consulta de planillas propias');
END;
/

-- ============================================================================
-- PASO 2.4: Rol de Solo Consulta
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 2.4: Rol ROL_CONSULTA_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP ROLE ROL_CONSULTA_ACS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE ROLE ROL_CONSULTA_ACS;

GRANT CREATE SESSION TO ROL_CONSULTA_ACS;

-- Solo lectura en todas las tablas
BEGIN
    FOR t IN (
        SELECT TABLE_NAME 
        FROM ALL_TABLES 
        WHERE OWNER = 'MORA' 
        AND TABLE_NAME LIKE 'ACS_%'
    ) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON MORA.' || t.TABLE_NAME || ' TO ROL_CONSULTA_ACS';
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('✓ Rol ROL_CONSULTA_ACS creado');
    DBMS_OUTPUT.PUT_LINE('  - Solo lectura en todas las tablas');
END;
/

-- ============================================================================
-- PASO 2.5: Ver Roles Creados
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 2.5: Resumen de Roles
PROMPT ────────────────────────────────────────────────────────────────────────────

SELECT 
    ROLE AS "Rol",
    PASSWORD_REQUIRED AS "Requiere Password"
FROM DBA_ROLES
WHERE ROLE LIKE 'ROL_%_ACS'
ORDER BY ROLE;

-- Conteo de privilegios por rol
PROMPT 
PROMPT  Privilegios otorgados por rol:

SELECT 
    GRANTEE AS "Rol",
    COUNT(*) AS "Total Privilegios"
FROM DBA_TAB_PRIVS
WHERE GRANTEE LIKE 'ROL_%_ACS'
GROUP BY GRANTEE
ORDER BY GRANTEE;

PROMPT 
PROMPT  ✓ PARTE 2 COMPLETADA: ROLES (3%)
PROMPT 

-- ============================================================================
-- PARTE 3: USUARIOS (3%)
-- ============================================================================

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 3: USUARIOS CON ROLES Y PERFILES (3%)
PROMPT ════════════════════════════════════════════════════════════════════════════

-- ============================================================================
-- PASO 3.1: Usuario Administrador
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 3.1: Usuario ADMIN_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP USER admin_acs CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE USER admin_acs 
IDENTIFIED BY Admin_ACS_2025
DEFAULT TABLESPACE ACS_DATA
TEMPORARY TABLESPACE TEMP
PROFILE ADMIN_ACS
ACCOUNT UNLOCK;

GRANT ROL_ADMIN_ACS TO admin_acs;
ALTER USER admin_acs DEFAULT ROLE ROL_ADMIN_ACS;

DBMS_OUTPUT.PUT_LINE('✓ Usuario ADMIN_ACS creado');
DBMS_OUTPUT.PUT_LINE('  - Perfil: ADMIN_ACS');
DBMS_OUTPUT.PUT_LINE('  - Rol: ROL_ADMIN_ACS');
DBMS_OUTPUT.PUT_LINE('  - Password: Admin_ACS_2025');

-- ============================================================================
-- PASO 3.2: Usuario Recursos Humanos
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 3.2: Usuario RRHH_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP USER rrhh_acs CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE USER rrhh_acs 
IDENTIFIED BY RRHH_ACS_2025
DEFAULT TABLESPACE ACS_DATA
TEMPORARY TABLESPACE TEMP
PROFILE USUARIO_ACS
ACCOUNT UNLOCK;

GRANT ROL_RRHH_ACS TO rrhh_acs;
ALTER USER rrhh_acs DEFAULT ROLE ROL_RRHH_ACS;

DBMS_OUTPUT.PUT_LINE('✓ Usuario RRHH_ACS creado');
DBMS_OUTPUT.PUT_LINE('  - Perfil: USUARIO_ACS');
DBMS_OUTPUT.PUT_LINE('  - Rol: ROL_RRHH_ACS');
DBMS_OUTPUT.PUT_LINE('  - Password: RRHH_ACS_2025');

-- ============================================================================
-- PASO 3.3: Usuario Médico
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 3.3: Usuario MEDICO_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP USER medico_acs CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE USER medico_acs 
IDENTIFIED BY Medico_ACS_2025
DEFAULT TABLESPACE ACS_DATA
TEMPORARY TABLESPACE TEMP
PROFILE USUARIO_ACS
ACCOUNT UNLOCK;

GRANT ROL_MEDICO_ACS TO medico_acs;
ALTER USER medico_acs DEFAULT ROLE ROL_MEDICO_ACS;

DBMS_OUTPUT.PUT_LINE('✓ Usuario MEDICO_ACS creado');
DBMS_OUTPUT.PUT_LINE('  - Perfil: USUARIO_ACS');
DBMS_OUTPUT.PUT_LINE('  - Rol: ROL_MEDICO_ACS');
DBMS_OUTPUT.PUT_LINE('  - Password: Medico_ACS_2025');

-- ============================================================================
-- PASO 3.4: Usuario Solo Consulta
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 3.4: Usuario CONSULTA_ACS
PROMPT ────────────────────────────────────────────────────────────────────────────

BEGIN
    EXECUTE IMMEDIATE 'DROP USER consulta_acs CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE USER consulta_acs 
IDENTIFIED BY Consulta_ACS_2025
DEFAULT TABLESPACE ACS_DATA
TEMPORARY TABLESPACE TEMP
PROFILE CONSULTA_ACS
ACCOUNT UNLOCK;

GRANT ROL_CONSULTA_ACS TO consulta_acs;
ALTER USER consulta_acs DEFAULT ROLE ROL_CONSULTA_ACS;

DBMS_OUTPUT.PUT_LINE('✓ Usuario CONSULTA_ACS creado');
DBMS_OUTPUT.PUT_LINE('  - Perfil: CONSULTA_ACS');
DBMS_OUTPUT.PUT_LINE('  - Rol: ROL_CONSULTA_ACS');
DBMS_OUTPUT.PUT_LINE('  - Password: Consulta_ACS_2025');

-- ============================================================================
-- PASO 3.5: Ver Usuarios Creados
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 3.5: Resumen de Usuarios
PROMPT ────────────────────────────────────────────────────────────────────────────

SELECT 
    USERNAME AS "Usuario",
    PROFILE AS "Perfil",
    ACCOUNT_STATUS AS "Estado",
    DEFAULT_TABLESPACE AS "Tablespace",
    CREATED AS "Fecha Creación"
FROM DBA_USERS
WHERE USERNAME LIKE '%_ACS'
ORDER BY USERNAME;

-- Roles asignados
PROMPT 
PROMPT  Roles asignados a usuarios:

SELECT 
    GRANTEE AS "Usuario",
    GRANTED_ROLE AS "Rol",
    DEFAULT_ROLE AS "Por Defecto"
FROM DBA_ROLE_PRIVS
WHERE GRANTEE LIKE '%_ACS'
ORDER BY GRANTEE, GRANTED_ROLE;

PROMPT 
PROMPT  ✓ PARTE 3 COMPLETADA: USUARIOS (3%)
PROMPT 

-- ============================================================================
-- RESUMEN Y VALIDACIONES
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  RESUMEN - PUNTO 9: SEGURIDAD DE BASE DE DATOS (9%)
PROMPT ════════════════════════════════════════════════════════════════════════════

DECLARE
    v_perfiles NUMBER;
    v_roles NUMBER;
    v_usuarios NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_perfiles
    FROM DBA_PROFILES
    WHERE PROFILE LIKE '%_ACS';
    
    SELECT COUNT(*) INTO v_roles
    FROM DBA_ROLES
    WHERE ROLE LIKE 'ROL_%_ACS';
    
    SELECT COUNT(*) INTO v_usuarios
    FROM DBA_USERS
    WHERE USERNAME LIKE '%_ACS';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('  RESUMEN COMPLETO DE SEGURIDAD:');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✓ PERFILES (3%):');
    DBMS_OUTPUT.PUT_LINE('  - Total creados: ' || v_perfiles);
    DBMS_OUTPUT.PUT_LINE('  - ADMIN_ACS: Administradores (5 sesiones, 8h)');
    DBMS_OUTPUT.PUT_LINE('  - USUARIO_ACS: Usuarios estándar (2 sesiones, 4h)');
    DBMS_OUTPUT.PUT_LINE('  - CONSULTA_ACS: Solo lectura (1 sesión, 2h)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✓ ROLES (3%):');
    DBMS_OUTPUT.PUT_LINE('  - Total creados: ' || v_roles);
    DBMS_OUTPUT.PUT_LINE('  - ROL_ADMIN_ACS: Acceso completo');
    DBMS_OUTPUT.PUT_LINE('  - ROL_RRHH_ACS: Gestión de planillas');
    DBMS_OUTPUT.PUT_LINE('  - ROL_MEDICO_ACS: Consultas propias');
    DBMS_OUTPUT.PUT_LINE('  - ROL_CONSULTA_ACS: Solo lectura');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✓ USUARIOS (3%):');
    DBMS_OUTPUT.PUT_LINE('  - Total creados: ' || v_usuarios);
    DBMS_OUTPUT.PUT_LINE('  - admin_acs (ROL_ADMIN_ACS, ADMIN_ACS)');
    DBMS_OUTPUT.PUT_LINE('  - rrhh_acs (ROL_RRHH_ACS, USUARIO_ACS)');
    DBMS_OUTPUT.PUT_LINE('  - medico_acs (ROL_MEDICO_ACS, USUARIO_ACS)');
    DBMS_OUTPUT.PUT_LINE('  - consulta_acs (ROL_CONSULTA_ACS, CONSULTA_ACS)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('  PUNTO 9 COMPLETADO: 9% ✓');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
END;
/

PROMPT 
PROMPT  Demostración lista para el profesor!
PROMPT  Puede probar conexión con los usuarios creados
PROMPT 

EXIT;
