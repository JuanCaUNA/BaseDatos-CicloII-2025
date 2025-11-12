
-- UNA VEZ CONFIGURADO LOS PARAMETROS Y CLAVES, CONFIGURAR ACLS, SE PUEDE PROBAR EL ENVIO DE CORREOS USANDO BREVO SMTP
BEGIN
    ACS_PRC_CORREO_NOTIFICADOR(
        'dbcarlosm@gmail.com',
        'Prueba de correo desde Oracle DB',
        'Este es un correo de prueba enviado desde Oracle Database utilizando UTL_SMTP.'
    );
END;