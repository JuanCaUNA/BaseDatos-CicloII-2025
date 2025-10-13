-- * JOBS GLOBAL

-- * Procedimeinto para enviar correo: ACS_PRC_CORREO_NOTIFICADOR (p_destinatario IN VARCHAR2, p_asunto IN VARCHAR2, p_mensaje IN VARCHAR2)
-- * Funcion para obtener parametros: ACS_FUN_OBTENER_PARAMETRO (p_clave_parametro IN VARCHAR2) RETURN VARCHAR2

-- * ABREVIATURA CHECK: CHK

-- ✓ Verificar el tamaño de los tablespace, el cual no debe de exceder en un 85% su 
-- tamaño.  Este proceso se ejecutará todos los días, notificar en caso de que 
-- exista inconsistencia 
CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_TABLESPACE AS
DECLARE
    -- CURSOR PARA RECORRER TABLESPACE EXCEDIDOS
    CURSOR C_TABLESPACE_EXCEDIDOS IS
        SELECT tablespace_name, ROUND((used_space / total_space) * 100, 2) AS used_percentage
        FROM (
            SELECT 
                tablespace_name,
                SUM(bytes) / (1024 * 1024) AS total_space,
                SUM(bytes) - SUM(free_bytes) / (1024 * 1024) AS used_space
            FROM dba_data_files df
            LEFT JOIN (
                SELECT tablespace_name, SUM(bytes) AS free_bytes
                FROM dba_free_space
                GROUP BY tablespace_name
            ) fs ON df.tablespace_name = fs.tablespace_name
            GROUP BY df.tablespace_name
        )
        WHERE (used_space / total_space) * 100 > 85;
    -- VARIABLES
    V_CORREO_DBA VARCHAR2(100);
    V_MENSAJE VARCHAR2(4000) := 'Los siguientes tablespaces han excedido el 85% de su capacidad:' || CHR(10);
    V_ASUNTO VARCHAR2(100) := 'Alerta de Tablespace Excedido';
    V_ENCONTRADOS BOOLEAN := FALSE;
BEGIN
    FOR R_TABLESPACE IN C_TABLESPACE_EXCEDIDOS LOOP
        V_ENCONTRADOS := TRUE;
        V_MENSAJE := V_MENSAJE || 'Tablespace: ' || R_TABLESPACE.tablespace_name || ', Uso: ' || R_TABLESPACE.used_percentage || '%' || CHR(10);
    END LOOP;

    IF V_ENCONTRADOS THEN
        V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
        ACS_PRC_CORREO_NOTIFICADOR(V_CORREO_DBA, V_ASUNTO, V_MENSAJE);
    END IF;
END;

-- ✓ Verifica si existen objetos inválidos. Este proceso se ejecutará todos los días, 
-- notificar en caso de que exista inconsistencia

CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_OBJETOS_INVALIDOS AS
DECLARE
    -- CURSOR PARA RECORRER OBJETOS INVALIDOS
    CURSOR C_OBJETOS_INVALIDOS IS
        SELECT owner, object_name, object_type
        FROM dba_objects
        WHERE status = 'INVALID';
    -- VARIABLES
    V_CORREO_DBA VARCHAR2(100);
    V_MENSAJE VARCHAR2(4000) := 'Los siguientes objetos están inválidos:' || CHR(10);
    V_ASUNTO VARCHAR2(100) := 'Objetos Inválidos en la Base de Datos';
    V_ENCONTRADOS BOOLEAN := FALSE;
BEGIN
    FOR R_OBJETO IN C_OBJETOS_INVALIDOS LOOP
        V_ENCONTRADOS := TRUE;
        V_MENSAJE := V_MENSAJE || 'Owner: ' || R_OBJETO.owner || ', Objeto: ' || R_OBJETO.object_name || ', Tipo: ' || R_OBJETO.object_type || CHR(10);
    END LOOP;

    IF V_ENCONTRADOS THEN
        V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
        ACS_PRC_CORREO_NOTIFICADOR(V_CORREO_DBA, V_ASUNTO, V_MENSAJE);
    END IF;
END;

-- ✓ En ocasiones los índices se dañan, verificar y notificar cuando esto sucede. Este 
-- proceso se ejecutará todos los días, notificar en caso de que exista 
-- inconsistencia 
-- PROCEDIMIENTO PARA VERIFICAR EL ESTADO DE LOS TABLESPACE

CREATE OR REPLACE PROCEDURE ACS_PRC_INDICES_CORRUCTOS AS
DECLARE
    -- CURSOR PARA RECORRER INDICES CORRUPTOS
    CURSOR C_INDICES_CORRUPTOS IS
        SELECT owner, index_name, table_name
        FROM dba_indexes
        WHERE status = 'UNUSABLE';
    -- VARIABLES
    V_CORREO_DBA VARCHAR2(100);
    V_MENSAJE VARCHAR2(4000) := 'Los siguientes índices están corruptos:' || CHR(10);
    V_ASUNTO VARCHAR2(100) := 'Índices Corruptos en la Base de Datos';
    V_ENCONTRADOS BOOLEAN := FALSE;
BEGIN
    FOR R_INDICE IN C_INDICES_CORRUPTOS LOOP
        V_ENCONTRADOS := TRUE;
        V_MENSAJE := V_MENSAJE || 'Owner: ' || R_INDICE.owner || ', Índice: ' || R_INDICE.index_name || ', Tabla: ' || R_INDICE.table_name || CHR(10);
    END LOOP;
    IF V_ENCONTRADOS THEN
        V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
        ACS_PRC_CORREO_NOTIFICADOR(V_CORREO_DBA, V_ASUNTO, V_MENSAJE);
    END IF;
END;

-- ! verificacion diaria
CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_DIARIAS AS
BEGIN
    BEGIN
        ACS_PRC_CHK_TABLESPACE;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error en ACS_PRC_CHK_TABLESPACE: ' || SQLERRM);
    END;

    BEGIN
        ACS_PRC_CHK_OBJETOS_INVALIDOS;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error en ACS_PRC_CHK_OBJETOS_INVALIDOS: ' || SQLERRM);
    END;

    BEGIN
        ACS_PRC_INDICES_CORRUCTOS;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error en ACS_PRC_INDICES_CORRUCTOS: ' || SQLERRM);
    END;
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