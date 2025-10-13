-- * JOBS

-- * Procedimeinto para enviar correo: ACS_FUN_CORREO_NOTIFICADOR (p_destinatario IN VARCHAR2, p_asunto IN VARCHAR2, p_mensaje IN VARCHAR2)
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
        SELECT PEP_ID, PEP_NOMBRE_USUARIO, PEP_FECHA_ULTIMO_ACCESO
        FROM ACS_PERSONAL
        WHERE PEP_ESTADO = 'ACTIVO'
            AND PEP_FECHA_ULTIMO_ACCESO <= ADD_MONTHS(SYSDATE, -3);
    -- VARIABLES
    V_CORREO_DBA VARCHAR2(100);
    V_MENSAJE VARCHAR2(4000) := 'Las siguientes cuentas han sido inactivadas por más de 3 meses de inactividad:' || CHR(10);
    V_ASUNTO VARCHAR2(100) := 'Cuentas Inactivas Inactivadas';
BEGIN
    FOR R_USUARIO IN C_USUARIOS_INACTIVOS LOOP
        UPDATE ACS_PERSONAL
        SET PEP_ESTADO = 'INACTIVO'
        WHERE PEP_ID = R_USUARIO.PEP_ID;
        
        V_MENSAJE := V_MENSAJE || 'Usuario: ' || R_USUARIO.PEP_NOMBRE_USUARIO || ', Último Acceso: ' || TO_CHAR(R_USUARIO.PEP_FECHA_ULTIMO_ACCESO, 'DD-MM-YYYY') || CHR(10);
    END LOOP;
    
    IF SQL%ROWCOUNT > 0 THEN
        IF V_CORREO_DBA IS NULL THEN
            V_CORREO_DBA := ACS_FUN_OBTENER_PARAMETRO('CORREO_DBA');
        END IF;
        
        ACS_FUN_CORREO_NOTIFICADOR(V_CORREO_DBA, V_ASUNTO, V_MENSAJE);
    END IF;
    
    COMMIT;
END;