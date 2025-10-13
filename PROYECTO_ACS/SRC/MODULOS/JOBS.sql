-- * JOBS GLOBAL

-- * Procedimeinto para enviar correo: ACS_FUN_CORREO_NOTIFICADOR (p_destinatario IN VARCHAR2, p_asunto IN VARCHAR2, p_mensaje IN VARCHAR2)
-- * Funcion para obtener parametros: ACS_FUN_OBTENER_PARAMETRO (p_clave_parametro IN VARCHAR2) RETURN VARCHAR2
-- * ABREVIATURA CHECK: CHK

-- ✓ Verificar el tamaño de los tablespace, el cual no debe de exceder en un 85% su 
-- tamaño.  Este proceso se ejecutará todos los días, notificar en caso de que 
-- exista inconsistencia 
CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_TABLESPACE AS
DECLARE
    -- VARIABLES
    V_CORREO_DBA VARCHAR2(100);
BEGIN
    -- CONSULTA PARA VERIFICAR EL USO DE CADA TABLESPACE
    FOR ts IN (
        SELECT tablespace_name, 
               ROUND((used_space/total_space)*100, 2) AS porcentaje_usado
        FROM (
            SELECT tablespace_name,
                   SUM(bytes)/1024/1024 AS total_space,
                   SUM(DECODE(status, 'AVAILABLE', bytes, 0))/1024/1024 AS used_space
            FROM dba_free_space
            GROUP BY tablespace_name
        )
    ) LOOP
        IF ts.porcentaje_usado > 85 THEN
            IF V_CORREO_DBA IS NULL THEN
                V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
            END IF;
            ACS_FUN_CORREO_NOTIFICADOR(
                V_CORREO_DBA, 
                'Tablespace Excedido', 
                'El tablespace ' || ts.tablespace_name || ' está al ' || ts.porcentaje_usado || '% de uso.');
        END IF;
    END LOOP;
END;

-- ✓ Verifica si existen objetos inválidos. Este proceso se ejecutará todos los días, 
-- notificar en caso de que exista inconsistencia

CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_OBJETOS_INVALIDOS AS
DECLARE
    -- VARIABLES
    V_CORREO_DBA VARCHAR2(100);
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_objects WHERE status = 'INVALID';
    IF v_count > 0 THEN
        IF V_CORREO_DBA IS NULL THEN
                V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
        END IF;
            ACS_FUN_CORREO_NOTIFICADOR(
                V_CORREO_DBA, 
                'Objetos Inválidos', 
                'Existen ' || v_count || ' objetos inválidos en la base de datos.');
    END IF;
END;

-- ✓ En ocasiones los índices se dañan, verificar y notificar cuando esto sucede. Este 
-- proceso se ejecutará todos los días, notificar en caso de que exista 
-- inconsistencia 
-- PROCEDIMIENTO PARA VERIFICAR EL ESTADO DE LOS TABLESPACE

CREATE OR REPLACE PROCEDURE ACS_PRC_INDICES_CORRUCTOS AS
DECLARE
    -- VARIABLES
    V_CORREO_DBA VARCHAR2(100);
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_indexes WHERE status = 'UNUSABLE';
    IF v_count > 0 THEN
       IF V_CORREO_DBA IS NULL THEN
                V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
            END IF;
            ACS_FUN_CORREO_NOTIFICADOR(
            V_CORREO_DBA, 
            'Índices Dañados', 
            'Existen ' || v_count || ' índices dañados (UNUSABLE) en la base de datos.');
    END IF;
END;

-- ! verificacion diaria
CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_DIARIAS AS
BEGIN
    VERIFICAR_TABLESPACE;
    VERIFICAR_OBJETOS_INVALIDOS;
    VERIFICAR_INDICES_CORRUCTOS;
END;

-- ** Job para ejecutar las verificaciones diarias a las 2 AM **
BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'job_verificaciones_diarias',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN ACS_PRC_CHK_DIARIAS; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=2',
        enabled         => TRUE
    );
END;
/