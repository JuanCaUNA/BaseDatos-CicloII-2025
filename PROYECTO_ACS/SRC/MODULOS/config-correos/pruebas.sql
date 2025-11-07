-- ** PRUEBAS Y VALIDACIONES**
-- (Opcional) Verificación del ACL
SELECT acl, principal, privilege, is_grant FROM dba_network_acl_privileges WHERE acl = ACS_FUN_OBTENER_PARAMETRO('SMTP_ACL_FILE');
SELECT host, lower_port, upper_port, acl FROM dba_network_acls WHERE host = ACS_FUN_OBTENER_PARAMETRO('SMTP_HOST');

-- VALIDACIÓN RÁPIDA DE ENCRIPTACIÓN/DESENCRIPTACIÓN (PRUEBA LOCAL)
DECLARE
    V_NAME VARCHAR2(50) := 'TEST_KEY_TEMP';
    V_TIPO VARCHAR2(20) := 'TEST';
    V_PLAIN VARCHAR2(100) := 'SECRETO123!@#';
    V_OUT VARCHAR2(100);
BEGIN
    ACS_PRC_GUARDAR_CLAVE(V_NAME, V_TIPO, V_PLAIN);
    V_OUT := ACS_FUN_OBTENER_CLAVE(V_NAME);
    IF V_OUT = V_PLAIN THEN
        DBMS_OUTPUT.PUT_LINE('[TEST] OK ROUNDTRIP AES-256-CBC');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[TEST] FAIL ROUNDTRIP: '||NVL(V_OUT,'<NULL>'));
    END IF;
    -- LIMPIEZA
    DELETE FROM ACS_CLAVE WHERE ACL_NOMBRE_CLAVE = V_NAME AND ACL_TIPO = V_TIPO;
    COMMIT;
END;
/

-- PROBAR LA FUNCIÓN POR SEPARADO
SELECT ACS_FUN_OBTENER_CLAVE('SMTP_CLAVE') AS CLAVE_RECUPERADA FROM DUAL;
/

-- PRUEBA CON UN DESTINATARIO (AJUSTE LOS CORREOS A SU ENTORNO)
BEGIN
    ACS_PRC_CORREO_NOTIFICADOR(
        P_DESTINATARIO => 'juancarlos19defebrero@gmail.com',
        P_ASUNTO       => 'Prueba única (Brevo 587 STARTTLS)',
        P_MENSAJE      => '<h1>Hola</h1><p>Mensaje de prueba desde Oracle 19c.</p>'
    );
END;
/

-- Prueba con múltiples destinatarios
BEGIN
    ACS_PRC_CORREO_NOTIFICADOR(
        P_DESTINATARIO => 'juancarlos19defebrero@gmail.com,estebangranados147@gmail.com',
        P_ASUNTO       => 'Prueba múltiple',
        P_MENSAJE      => '<p>Hola a todos.</p>'
    );
END;
/
