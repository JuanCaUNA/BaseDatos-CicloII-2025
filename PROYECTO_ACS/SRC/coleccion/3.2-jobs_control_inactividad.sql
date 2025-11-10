-- * JOBS

-- * Procedimiento para enviar correo: ACS_PRC_CORREO_NOTIFICADOR (p_destinatario IN VARCHAR2, p_asunto IN VARCHAR2, p_mensaje IN VARCHAR2)
-- * Función para obtener parámetros: ACS_FUN_OBTENER_PARAMETRO (p_clave_parametro IN VARCHAR2) RETURN VARCHAR2
-- * ABREVIATURA CHECK: CHK

-- ✓ Realizar un proceso que inactiva cuentas de usuarios que tengan más de 3 
-- meses de inactividad; este proceso se ejecutará una vez al mes y notificará 
-- al DBA cuáles cuentas fueron inactivadas.

CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_CUENTAS_INACTIVAS AS
    -- CURSOR PARA RECORRER USUARIOS INACTIVOS (según ACS_USUARIO y ACS_PERSONA)
    CURSOR C_USUARIOS_INACTIVOS IS
        SELECT 
            U.AUS_ID,
            U.AUS_ULTIMO_ACCESO,
            P.APE_EMAIL,
            TRIM(P.APE_NOMBRE || ' ' || P.APE_P_APELLIDO || NVL2(P.APE_S_APELLIDO, ' ' || P.APE_S_APELLIDO, '')) AS NOMBRE_COMPLETO
        FROM ACS_USUARIO U
        JOIN ACS_PERSONA P ON P.APE_ID = U.APE_ID
        WHERE U.AUS_ESTADO = 'ACTIVO'
          AND U.AUS_ULTIMO_ACCESO <= ADD_MONTHS(SYSDATE, -3);

    -- PARÁMETROS
    V_CORREO_DBA VARCHAR2(255);

    -- VARIABLES
    V_MENSAJE  VARCHAR2(32767) := 'Las siguientes cuentas han sido inactivadas por más de 3 meses de inactividad:' || CHR(10);
    V_ASUNTO   VARCHAR2(200) := 'Cuentas inactivadas por inactividad';
    V_INACTIVADOS NUMBER := 0;
BEGIN
    FOR R_USUARIO IN C_USUARIOS_INACTIVOS LOOP
        UPDATE ACS_USUARIO
           SET AUS_ESTADO = 'INACTIVO'
         WHERE AUS_ID = R_USUARIO.AUS_ID;

        IF SQL%ROWCOUNT > 0 THEN
            V_INACTIVADOS := V_INACTIVADOS + 1;
            V_MENSAJE := V_MENSAJE 
                || 'Usuario ID: ' || R_USUARIO.AUS_ID
                || ', Nombre: ' || R_USUARIO.NOMBRE_COMPLETO
                || ', Email: '  || R_USUARIO.APE_EMAIL
                || ', Último Acceso: ' || TO_CHAR(R_USUARIO.AUS_ULTIMO_ACCESO, 'DD-MM-YYYY HH24:MI:SS')
                || CHR(10);
        END IF;
    END LOOP;

    IF V_INACTIVADOS > 0 THEN
        BEGIN
            V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
        EXCEPTION
            WHEN OTHERS THEN
                V_CORREO_DBA := NULL;
        END;

        IF V_CORREO_DBA IS NOT NULL THEN
            ACS_PRC_CORREO_NOTIFICADOR(V_CORREO_DBA, V_ASUNTO, V_MENSAJE);
        END IF;
    END IF;

    COMMIT;
END;
/

-- DEFINICIÓN DEL JOB MENSUAL
BEGIN
    -- Intento de eliminar el job si existe para recrearlo limpio
    BEGIN
        DBMS_SCHEDULER.DROP_JOB('ACS_JOB_CHK_CUENTAS_INACTIVAS', FORCE => TRUE);
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'ACS_JOB_CHK_CUENTAS_INACTIVAS',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'ACS_PRC_CHK_CUENTAS_INACTIVAS',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=1;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Job para inactivar cuentas de usuarios (ACS_USUARIO) con más de 3 meses de inactividad'
    );
END;
/