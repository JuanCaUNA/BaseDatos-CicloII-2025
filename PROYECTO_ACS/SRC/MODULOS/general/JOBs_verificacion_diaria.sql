-- * JOBS GLOBAL

/*
!Notas:
    * Procedimeinto para enviar correo: 
        ACS_PRC_CORREO_NOTIFICADOR (p_destinatario IN VARCHAR2, p_asunto IN VARCHAR2, p_mensaje IN VARCHAR2)

    * Funcion para obtener parametros: 
        ACS_FUN_OBTENER_PARAMETRO (p_clave_parametro IN VARCHAR2) RETURN VARCHAR2

    * ABREVIATURA 
        CHECK(revisar): CHK
        P_ = PARAMETRO. para definir parámetros de entrada
        V_ = VARIABLE. para asignar valores
        R_ = RECORD. para recorrer cursores
        C_ = CURSOR. para definir una consulta a la cual se va a recorrer
*/

CREATE OR REPLACE PACKAGE ACS_PKG_CHK_MONITOR AS
    PROCEDURE CHK_TABLESPACE;
    PROCEDURE CHK_OBJETOS_INVALIDOS;
    PROCEDURE CHK_INDICES_CORRUPTOS;
    PROCEDURE CHK_DIARIAS;
END ACS_CHK_MONITOR;
/

CREATE OR REPLACE PACKAGE BODY ACS_CHK_MONITOR AS
-- ** ✓ Verificar el tamaño de los tablespace, el cual no debe de exceder en un 85% su tamaño entonces notificar al DBA, diario. **
    PROCEDURE CHK_TABLESPACE AS
    DECLARE
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

        P_CORREO_DBA ACS_PARAMETROS.APA_VALOR_PARAMETRO%TYPE;

        V_MENSAJE VARCHAR2(4000) := 'Los siguientes tablespaces han excedido el 85% de su capacidad:' || CHR(10);
        V_ASUNTO VARCHAR2(100) := 'Alerta de Tablespace Excedido';
        V_ENCONTRADOS BOOLEAN := FALSE;
    BEGIN
        FOR R_TABLESPACE IN C_TABLESPACE_EXCEDIDOS LOOP
            V_ENCONTRADOS := TRUE;
            V_MENSAJE := V_MENSAJE || 'Tablespace: ' || R_TABLESPACE.tablespace_name || ', Uso: ' || R_TABLESPACE.used_percentage || '%' || CHR(10);
        END LOOP;

        IF V_ENCONTRADOS THEN
            P_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
            ACS_PRC_CORREO_NOTIFICADOR(P_CORREO_DBA, V_ASUNTO, V_MENSAJE);
        END IF;
    END CHK_TABLESPACE;

-- ** ✓ Verifica si existen objetos inválidos entonces notificar al DBA, diario. ** 
    PROCEDURE CHK_OBJETOS_INVALIDOS AS
    DECLARE
        CURSOR C_OBJETOS_INVALIDOS IS
            SELECT owner, object_name, object_type
            FROM dba_objects
            WHERE status = 'INVALID';

        P_CORREO_DBA ACS_PARAMETROS.APA_VALOR_PARAMETRO%TYPE;

        V_MENSAJE VARCHAR2(4000) := 'Los siguientes objetos están inválidos:' || CHR(10);
        V_ASUNTO VARCHAR2(100) := 'Objetos Inválidos en la Base de Datos';
        V_ENCONTRADOS BOOLEAN := FALSE;
    BEGIN
        FOR R_OBJETO IN C_OBJETOS_INVALIDOS LOOP
            V_ENCONTRADOS := TRUE;
            V_MENSAJE := V_MENSAJE || 'Owner: ' || R_OBJETO.owner || ', Objeto: ' || R_OBJETO.object_name || ', Tipo: ' || R_OBJETO.object_type || CHR(10);
        END LOOP;

        IF V_ENCONTRADOS THEN
            P_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
            ACS_PRC_CORREO_NOTIFICADOR(P_CORREO_DBA, V_ASUNTO, V_MENSAJE);
        END IF;
    END CHK_OBJETOS_INVALIDOS;

-- ** ✓ En ocasiones los índices se dañan, verificar entonces notificar al DBA, diario. **
    PROCEDURE CHK_INDICES_CORRUPTOS AS
    DECLARE
        CURSOR C_INDICES_CORRUPTOS IS
            SELECT owner, index_name, table_name
            FROM dba_indexes
            WHERE status = 'UNUSABLE';

        P_CORREO_DBA ACS_PARAMETROS.APA_VALOR_PARAMETRO%TYPE;

        V_MENSAJE VARCHAR2(4000) := 'Los siguientes índices están corruptos:' || CHR(10);
        V_ASUNTO VARCHAR2(100) := 'Índices Corruptos en la Base de Datos';
        V_ENCONTRADOS BOOLEAN := FALSE;
    BEGIN
        FOR R_INDICE IN C_INDICES_CORRUPTOS LOOP
            V_ENCONTRADOS := TRUE;
            V_MENSAJE := V_MENSAJE || 'Owner: ' || R_INDICE.owner || ', Índice: ' || R_INDICE.index_name || ', Tabla: ' || R_INDICE.table_name || CHR(10);
        END LOOP;

        IF V_ENCONTRADOS THEN
            P_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
            ACS_PRC_CORREO_NOTIFICADOR(P_CORREO_DBA, V_ASUNTO, V_MENSAJE);
        END IF;
    END CHK_INDICES_CORRUPTOS;

-- ** ✓ Procedimiento para ejecutar las verificaciones diarias **
    PROCEDURE CHK_DIARIAS AS
    BEGIN
        BEGIN
            CHK_TABLESPACE;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error en CHK_TABLESPACE: ' || SQLERRM);
        END;

        BEGIN
            CHK_OBJETOS_INVALIDOS;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error en CHK_OBJETOS_INVALIDOS: ' || SQLERRM);
        END;

        BEGIN
            CHK_INDICES_CORRUPTOS;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error en CHK_INDICES_CORRUPTOS: ' || SQLERRM);
        END;
    END CHK_DIARIAS;
END ACS_CHK_MONITOR;
/

-- ** Job para ejecutar las verificaciones diarias a las 2 AM **
BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'ACS_CHK_JOB_DIARIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN ACS_CHK_MONITOR.CHK_DIARIAS; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=2',
        enabled         => TRUE
    );
END;
/