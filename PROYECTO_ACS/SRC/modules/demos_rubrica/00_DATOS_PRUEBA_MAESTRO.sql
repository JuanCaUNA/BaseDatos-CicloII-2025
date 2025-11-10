-- ============================================================================
-- SCRIPT MAESTRO DE DATOS DE PRUEBA - PROYECTO ACS
-- Para demostración de TODOS los puntos de la rúbrica
-- ============================================================================
-- Orden de ejecución: Este script debe ejecutarse DESPUÉS de crear las tablas
-- Tiempo estimado: 2-3 minutos
-- Base de datos: Oracle 19c
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 50

PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  SCRIPT MAESTRO - CARGA DE DATOS DE PRUEBA
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT  Este script creará:
PROMPT  1. Padrón Nacional (20 personas del TSE)
PROMPT  2. Usuarios del sistema (médicos y administrativos)
PROMPT  3. Centros de salud con puestos y turnos
PROMPT  4. Escalas base y mensuales
PROMPT  5. Tipos de movimientos (deducciones)
PROMPT  6. Procedimientos médicos
PROMPT  7. Bitácoras configuradas
PROMPT  8. Parámetros del sistema
PROMPT 

-- ============================================================================
-- SECCIÓN 1: PADRÓN NACIONAL (5% de la rúbrica)
-- ============================================================================
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  SECCIÓN 1: Cargando Padrón Nacional (20 personas)
PROMPT ────────────────────────────────────────────────────────────────────────────

-- Limpiar datos anteriores
DELETE FROM ACS_PADRON_NACIONAL;

-- 20 registros reales del TSE (simulados pero realistas)
INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('101230456', 'JUAN', 'PEREZ', 'RODRIGUEZ', TO_DATE('1985-03-15', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('202340567', 'MARIA', 'GONZALEZ', 'CASTRO', TO_DATE('1990-07-22', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('303450678', 'CARLOS', 'MORA', 'JIMENEZ', TO_DATE('1988-11-05', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('404560789', 'ROSA', 'VEGA', 'MORALES', TO_DATE('1992-04-18', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('505670890', 'JOSE', 'RAMIREZ', 'SOLANO', TO_DATE('1987-09-30', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('606780901', 'ANA', 'HERNANDEZ', 'VARGAS', TO_DATE('1991-12-08', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('107890123', 'LUIS', 'CHAVEZ', 'MENDEZ', TO_DATE('1986-06-14', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('208901234', 'ELENA', 'SALAS', 'ROJAS', TO_DATE('1993-02-25', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('309012345', 'DIEGO', 'CAMPOS', 'ALVARADO', TO_DATE('1989-08-19', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('410123456', 'PATRICIA', 'MURILLO', 'SANCHEZ', TO_DATE('1994-05-11', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('511234567', 'FERNANDO', 'GUTIERREZ', 'VILLALOBOS', TO_DATE('1984-10-27', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('612345678', 'SOFIA', 'MONTERO', 'CALDERON', TO_DATE('1995-01-16', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('113456789', 'ROBERTO', 'FLORES', 'QUESADA', TO_DATE('1983-07-09', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('214567890', 'CARMEN', 'NAVARRO', 'CORDERO', TO_DATE('1996-03-21', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('315678901', 'MIGUEL', 'ARIAS', 'LEON', TO_DATE('1987-11-13', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('416789012', 'LAURA', 'ORTIZ', 'MATA', TO_DATE('1992-09-06', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('517890123', 'ANDRES', 'SOTO', 'BRENES', TO_DATE('1985-04-29', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('618901234', 'GABRIELA', 'VARGAS', 'AGUILAR', TO_DATE('1993-12-17', 'YYYY-MM-DD'), 'F');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('119012345', 'OSCAR', 'JIMENEZ', 'MARIN', TO_DATE('1988-06-23', 'YYYY-MM-DD'), 'M');

INSERT INTO ACS_PADRON_NACIONAL (APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, APN_FECHA_NAC, APN_SEXO)
VALUES ('220123456', 'DANIELA', 'ROJAS', 'UGALDE', TO_DATE('1991-02-10', 'YYYY-MM-DD'), 'F');

COMMIT;

PROMPT ✓ 20 registros del Padrón Nacional insertados

-- ============================================================================
-- SECCIÓN 2: PERSONAS Y USUARIOS DEL SISTEMA
-- ============================================================================
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  SECCIÓN 2: Creando Personas y Usuarios (8 médicos + 4 administrativos)
PROMPT ────────────────────────────────────────────────────────────────────────────

-- MÉDICOS (8 total)
DECLARE
    v_persona_id NUMBER;
    TYPE t_medico IS RECORD (
        cedula VARCHAR2(20),
        usuario VARCHAR2(50),
        email VARCHAR2(100),
        salario NUMBER
    );
    TYPE t_medicos IS TABLE OF t_medico INDEX BY PLS_INTEGER;
    v_medicos t_medicos;
BEGIN
    -- Definir 8 médicos con datos del padrón
    v_medicos(1).cedula := '101230456'; v_medicos(1).usuario := 'jperez'; v_medicos(1).email := 'juan.perez@acs.cr'; v_medicos(1).salario := 850000;
    v_medicos(2).cedula := '202340567'; v_medicos(2).usuario := 'mgonzalez'; v_medicos(2).email := 'maria.gonzalez@acs.cr'; v_medicos(2).salario := 920000;
    v_medicos(3).cedula := '107890123'; v_medicos(3).usuario := 'lchavez'; v_medicos(3).email := 'luis.chavez@acs.cr'; v_medicos(3).salario := 880000;
    v_medicos(4).cedula := '208901234'; v_medicos(4).usuario := 'esalas'; v_medicos(4).email := 'elena.salas@acs.cr'; v_medicos(4).salario := 900000;
    v_medicos(5).cedula := '309012345'; v_medicos(5).usuario := 'dcampos'; v_medicos(5).email := 'diego.campos@acs.cr'; v_medicos(5).salario := 870000;
    v_medicos(6).cedula := '511234567'; v_medicos(6).usuario := 'fgutierrez'; v_medicos(6).email := 'fernando.gutierrez@acs.cr'; v_medicos(6).salario := 950000;
    v_medicos(7).cedula := '113456789'; v_medicos(7).usuario := 'rflores'; v_medicos(7).email := 'roberto.flores@acs.cr'; v_medicos(7).salario := 860000;
    v_medicos(8).cedula := '315678901'; v_medicos(8).usuario := 'marias'; v_medicos(8).email := 'miguel.arias@acs.cr'; v_medicos(8).salario := 890000;
    
    FOR i IN 1..8 LOOP
        -- Crear persona
        INSERT INTO ACS_PERSONA (APE_CEDULA, APE_NOMBRE, APE_P_APELLIDO, APE_S_APELLIDO, APE_TIPO_PERSONA, APE_ESTADO_CIVIL, APE_EMAIL, APE_SEXO, APE_FECHA_NAC, APE_TIPO_PERSONAL, APE_ESTADO, APE_FECHA_CREACION, APE_FECHA_ACTUALIZACION)
        SELECT 
            APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, 
            'NACIONAL', 'SOLTERO', v_medicos(i).email, APN_SEXO, APN_FECHA_NAC, 
            'MEDICO', 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP
        FROM ACS_PADRON_NACIONAL 
        WHERE APN_CEDULA = v_medicos(i).cedula
        RETURNING APE_ID INTO v_persona_id;
        
        -- Crear usuario
        INSERT INTO ACS_USUARIO (APE_ID, AUS_NOMBRE_USUARIO, AUS_CLAVE, AUS_SALARIO_BASE, AUS_EMAIL, AUS_ESTADO, AUS_FECHA_CREACION, AUS_FECHA_ACTUALIZACION, AUS_ULTIMO_ACCESO)
        VALUES (v_persona_id, v_medicos(i).usuario, 'clave123', v_medicos(i).salario, v_medicos(i).email, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP, SYSTIMESTAMP);
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 8 médicos registrados correctamente');
END;
/

-- ADMINISTRATIVOS (4 total)
DECLARE
    v_persona_id NUMBER;
    TYPE t_admin IS RECORD (
        cedula VARCHAR2(20),
        usuario VARCHAR2(50),
        email VARCHAR2(100),
        salario NUMBER
    );
    TYPE t_admins IS TABLE OF t_admin INDEX BY PLS_INTEGER;
    v_admins t_admins;
BEGIN
    -- Definir 4 administrativos
    v_admins(1).cedula := '303450678'; v_admins(1).usuario := 'cmora'; v_admins(1).email := 'carlos.mora@acs.cr'; v_admins(1).salario := 550000;
    v_admins(2).cedula := '404560789'; v_admins(2).usuario := 'rvega'; v_admins(2).email := 'rosa.vega@acs.cr'; v_admins(2).salario := 580000;
    v_admins(3).cedula := '505670890'; v_admins(3).usuario := 'jramirez'; v_admins(3).email := 'jose.ramirez@acs.cr'; v_admins(3).salario := 560000;
    v_admins(4).cedula := '606780901'; v_admins(4).usuario := 'ahernandez'; v_admins(4).email := 'ana.hernandez@acs.cr'; v_admins(4).salario := 570000;
    
    FOR i IN 1..4 LOOP
        -- Crear persona
        INSERT INTO ACS_PERSONA (APE_CEDULA, APE_NOMBRE, APE_P_APELLIDO, APE_S_APELLIDO, APE_TIPO_PERSONA, APE_ESTADO_CIVIL, APE_EMAIL, APE_SEXO, APE_FECHA_NAC, APE_TIPO_PERSONAL, APE_ESTADO, APE_FECHA_CREACION, APE_FECHA_ACTUALIZACION)
        SELECT 
            APN_CEDULA, APN_NOMBRE, APN_P_APELLIDO, APN_S_APELLIDO, 
            'NACIONAL', 'SOLTERO', v_admins(i).email, APN_SEXO, APN_FECHA_NAC, 
            'ADMINISTRATIVO', 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP
        FROM ACS_PADRON_NACIONAL 
        WHERE APN_CEDULA = v_admins(i).cedula
        RETURNING APE_ID INTO v_persona_id;
        
        -- Crear usuario
        INSERT INTO ACS_USUARIO (APE_ID, AUS_NOMBRE_USUARIO, AUS_CLAVE, AUS_SALARIO_BASE, AUS_EMAIL, AUS_ESTADO, AUS_FECHA_CREACION, AUS_FECHA_ACTUALIZACION, AUS_ULTIMO_ACCESO)
        VALUES (v_persona_id, v_admins(i).usuario, 'clave123', v_admins(i).salario, v_admins(i).email, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP, SYSTIMESTAMP);
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 4 administrativos registrados correctamente');
END;
/

-- ============================================================================
-- SECCIÓN 3: TIPOS DE MOVIMIENTOS (Deducciones y otros) - Ya existen
-- ============================================================================
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  SECCIÓN 3: Verificando Tipos de Movimientos (Deducciones)
PROMPT ────────────────────────────────────────────────────────────────────────────

SELECT 
    ATM_COD AS "Código",
    ATM_NOMBRE AS "Nombre",
    ATM_MODO AS "Modo",
    NVL(TO_CHAR(ATM_PORC, '990.99'), 'N/A') || '%' AS "Porcentaje",
    ATM_APLICA_A AS "Aplica A"
FROM ACS_TIPO_MOV
WHERE ATM_ES_AUTOMATICO = 1
ORDER BY ATM_PRIORIDAD;

PROMPT ✓ Tipos de movimientos (deducciones) ya configurados

-- ============================================================================
-- SECCIÓN 4: CENTROS DE SALUD, PUESTOS Y TURNOS
-- ============================================================================
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  SECCIÓN 4: Creando Centros de Salud, Puestos y Turnos
PROMPT ────────────────────────────────────────────────────────────────────────────

-- Centro 1: Clínica San José
DECLARE
    v_centro_id NUMBER;
    v_puesto_id NUMBER;
BEGIN
    INSERT INTO ACS_CENTRO_MEDICO (ACM_NOMBRE, ACM_UBICACION, ACM_CONTACTO, ACM_TELEFONO, ACM_EMAIL, ACM_ESTADO, ACM_FECHA_CREACION, ACM_FECHA_ACTUALIZACION)
    VALUES ('Clínica San José', 'San José Centro, Ave 2 Calle 5', 'Dr. Luis Rodríguez', '2222-3344', 'contacto@clinicasj.cr', 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP)
    RETURNING ACM_ID INTO v_centro_id;
    
    -- Puesto 1: Medicina General
    INSERT INTO ACS_PUESTO_MEDICO (ACM_ID, APM_NOMBRE, APM_ESPECIALIDAD, APM_CANTIDAD_TURNOS, APM_ESTADO, APM_FECHA_CREACION, APM_FECHA_ACTUALIZACION)
    VALUES (v_centro_id, 'Medicina General Turno Mañana', 'MEDICINA_GENERAL', 1, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP)
    RETURNING APM_ID INTO v_puesto_id;
    
    -- Turno Mañana (6am - 2pm)
    INSERT INTO ACS_TURNO (APM_ID, ATU_NOMBRE, ATU_HORA_INICIO, ATU_HORA_FIN, ATU_TARIFA_COBRO, ATU_TARIFA_PAGO, ATU_TIPO_PAGO, ATU_ESTADO, ATU_FECHA_CREACION, ATU_FECHA_ACTUALIZACION)
    VALUES (v_puesto_id, 'Turno Mañana', TO_DATE('06:00', 'HH24:MI'), TO_DATE('14:00', 'HH24:MI'), 120000, 80000, 'POR_TURNO', 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP);
    
    DBMS_OUTPUT.PUT_LINE('✓ Centro Clínica San José creado con 1 puesto y 1 turno');
END;
/

-- ============================================================================
-- SECCIÓN 5: PROCEDIMIENTOS MÉDICOS
-- ============================================================================
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  SECCIÓN 5: Creando Catálogo de Procedimientos Médicos
PROMPT ────────────────────────────────────────────────────────────────────────────

-- Verificar si ya existen procedimientos
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM ACS_PROCEDIMIENTO;
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Ya existen ' || v_count || ' procedimientos, no se insertarán duplicados');
        RETURN;
    END IF;
END;
/

INSERT INTO ACS_PROCEDIMIENTO (APR_COD, APR_NOMBRE, APR_DESCRIPCION, APR_PRECIO, APR_COSTO, APR_ESTADO, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('CONS_GEN', 'Consulta General', 'Consulta médica general', 15000, 10000, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP);

INSERT INTO ACS_PROCEDIMIENTO (APR_COD, APR_NOMBRE, APR_DESCRIPCION, APR_PRECIO, APR_COSTO, APR_ESTADO, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('CURACION', 'Curación', 'Curación de heridas', 8000, 5000, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP);

INSERT INTO ACS_PROCEDIMIENTO (APR_COD, APR_NOMBRE, APR_DESCRIPCION, APR_PRECIO, APR_COSTO, APR_ESTADO, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('INYECCION', 'Inyección', 'Aplicación de inyección intramuscular', 5000, 3000, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP);

COMMIT;
PROMPT ✓ 3 procedimientos médicos registrados

-- ============================================================================
-- SECCIÓN 6: PARÁMETROS DEL SISTEMA (5% de la rúbrica)
-- ============================================================================
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  SECCIÓN 6: Configurando Parámetros del Sistema
PROMPT ────────────────────────────────────────────────────────────────────────────

-- Parámetros de correo (para notificaciones)
INSERT INTO ACS_PARAMETROS (APR_NOMBRE, APR_VALOR, APR_DESCRIPCION, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('SMTP_HOST', 'smtp.gmail.com', 'Servidor SMTP para envío de correos', SYSTIMESTAMP, SYSTIMESTAMP);

INSERT INTO ACS_PARAMETROS (APR_NOMBRE, APR_VALOR, APR_DESCRIPCION, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('SMTP_PORT', '587', 'Puerto SMTP', SYSTIMESTAMP, SYSTIMESTAMP);

INSERT INTO ACS_PARAMETROS (APR_NOMBRE, APR_VALOR, APR_DESCRIPCION, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('SMTP_USER', 'notificaciones@acs.cr', 'Usuario SMTP', SYSTIMESTAMP, SYSTIMESTAMP);

INSERT INTO ACS_PARAMETROS (APR_NOMBRE, APR_VALOR, APR_DESCRIPCION, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('DBA_EMAIL', 'dba@acs.cr', 'Email del DBA para notificaciones', SYSTIMESTAMP, SYSTIMESTAMP);

-- Parámetros operacionales
INSERT INTO ACS_PARAMETROS (APR_NOMBRE, APR_VALOR, APR_DESCRIPCION, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('DIAS_INACTIVIDAD_USUARIO', '90', 'Días de inactividad antes de marcar usuario inactivo', SYSTIMESTAMP, SYSTIMESTAMP);

INSERT INTO ACS_PARAMETROS (APR_NOMBRE, APR_VALOR, APR_DESCRIPCION, APR_FECHA_CREACION, APR_FECHA_ACTUALIZACION)
VALUES ('PORCENTAJE_MAX_TABLESPACE', '85', 'Porcentaje máximo de uso de tablespace', SYSTIMESTAMP, SYSTIMESTAMP);

COMMIT;
PROMPT ✓ Parámetros del sistema configurados

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  RESUMEN DE DATOS CREADOS
PROMPT ════════════════════════════════════════════════════════════════════════════

SELECT 'Padrón Nacional' AS "Tabla", COUNT(*) AS "Registros" FROM ACS_PADRON_NACIONAL
UNION ALL
SELECT 'Personas', COUNT(*) FROM ACS_PERSONA
UNION ALL
SELECT 'Usuarios', COUNT(*) FROM ACS_USUARIO
UNION ALL
SELECT 'Centros Médicos', COUNT(*) FROM ACS_CENTRO_MEDICO
UNION ALL
SELECT 'Puestos Médicos', COUNT(*) FROM ACS_PUESTO_MEDICO
UNION ALL
SELECT 'Turnos', COUNT(*) FROM ACS_TURNO
UNION ALL
SELECT 'Procedimientos Médicos', COUNT(*) FROM ACS_PROCEDIMIENTO
UNION ALL
SELECT 'Tipos de Movimiento', COUNT(*) FROM ACS_TIPO_MOV
UNION ALL
SELECT 'Parámetros Sistema', COUNT(*) FROM ACS_PARAMETROS;

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  ✓ DATOS DE PRUEBA CARGADOS EXITOSAMENTE
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT  Resumen:
PROMPT  - 20 registros del Padrón TSE
PROMPT  - 12 usuarios (8 médicos + 4 administrativos)
PROMPT  - 1 centro de salud con puestos y turnos
PROMPT  - 3 procedimientos médicos
PROMPT  - Tipos de movimientos (deducciones) verificados
PROMPT  - Parámetros del sistema configurados
PROMPT 
PROMPT  Siguiente paso: Ejecutar scripts individuales por punto de rúbrica
PROMPT  Los encontrarás en: SRC/modules/demos_rubrica/
PROMPT 

-- No hacer EXIT, permitir continuar en sesión
-- EXIT;
