-- * JOBS

-- * Procedimeinto para enviar correo: ACS_PRC_CORREO_NOTIFICADOR (p_destinatario IN VARCHAR2, p_asunto IN VARCHAR2, p_mensaje IN VARCHAR2)
-- * Funcion para obtener parametros: ACS_FUN_OBTENER_PARAMETRO (p_clave_parametro IN VARCHAR2) RETURN VARCHAR2
-- * ABREVIATURA CHECK: CHK

-- ✓ Realizar un proceso que inactive cuentas de usuarios que tengan más de 3 
-- meses de inactividad en planillas, escalas o procedimiento, este proceso se 
-- ejecutará una vez al mes y se notificara al DBA, cuales cuentas fueron 
-- inactivadas.

CREATE OR REPLACE PROCEDURE ACS_PRC_CHK_CUENTAS_INACTIVAS AS
DECLARE
    -- CURSOR PARA RECORRER USUARIOS INACTIVOS
    CURSOR C_USUARIOS_INACTIVOS IS
        SELECT PEP_ID, PEP_NOMBRE_USUARIO, AUS_ULTIMO_ACCESO
        FROM ACS_USUARIO
        WHERE AUS_ESTADO = 'ACTIVO'
            AND AUS_ULTIMO_ACCESO <= ADD_MONTHS(SYSDATE, -3);
    -- PARAMETROS
    P_CORREO_DBA ACS_PARAMETROS.APA_VALOR_PARAMETRO%TYPE;
    -- VARIABLES
    V_MENSAJE VARCHAR2(4000) := 'Las siguientes cuentas han sido inactivadas por más de 3 meses de inactividad:' || CHR(10);
    V_ASUNTO VARCHAR2(100) := 'Cuentas Inactivas Inactivadas';
BEGIN
    FOR R_USUARIO IN C_USUARIOS_INACTIVOS LOOP
        UPDATE ACS_PERSONAL
        SET PEP_ESTADO = 'INACTIVO'
        WHERE PEP_ID = R_USUARIO.PEP_ID;
        
        V_MENSAJE := V_MENSAJE || 'Usuario: ' || R_USUARIO.PEP_NOMBRE_USUARIO || ', Último Acceso: ' || TO_CHAR(R_USUARIO.AUS_ULTIMO_ACCESO, 'DD-MM-YYYY') || CHR(10);
    END LOOP;
    
    IF SQL%ROWCOUNT > 0 THEN
        P_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
        ACS_PRC_CORREO_NOTIFICADOR(P_CORREO_DBA, V_ASUNTO, V_MENSAJE);
    END IF;
    
    COMMIT;
END;

-- DEFINICION DEL JOB PARA CADA SEMANA 
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'ACS_JOB_CHK_CUENTAS_INACTIVAS',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'ACS_PRC_CHK_CUENTAS_INACTIVAS',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=1;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Job para inactivar cuentas de usuarios con más de 3 meses de inactividad'
    );
END;