
-- envio de correo
BEGIN
    ACS_PRC_CORREO_NOTIFICADOR(
        'frankodbz@gmail.com',
        'Prueba de correo desde Oracle DB',
        'Este es un correo de prueba enviado desde Oracle Database utilizando UTL_SMTP.'
    );
END;