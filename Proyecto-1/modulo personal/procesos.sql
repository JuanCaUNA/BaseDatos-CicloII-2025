-- PROCEDIMIENTO DE ENVIO DE CORREO NOTIFICADOR
CREATE OR REPLACE PROCEDURE ENVIAR_CORREO_NOTIFICADOR (
    P_DESTINATARIO IN VARCHAR2,
    P_ASUNTO IN VARCHAR2,
    P_MENSAJE IN VARCHAR2
) 
RETURNS VARCHAR2 -- PARA CONFIRMACION VALIDAR OK
IS
DECLARE
    -- CONFIGURACION
    C_SMTP_HOST CONSTANT VARCHAR2(100) := '127.0.0.1';
    C_SMTP_PORT CONSTANT NUMBER := 25;
    C_REMITENTE CONSTANT VARCHAR2(100) := 'oracle@midominio.local';
    -- VARIABLES
    MAIL_CONN UTL_SMTP.CONNECTION;
    CRLF CONSTANT VARCHAR2(2) := UTL_TCP.CRLF;
BEGIN
    -- CONECTAR CON HMAILSERVER, LOCAL SIN TLS
    MAIL_CONN := UTL_SMTP.OPEN_CONNECTION(C_SMTP_HOST, C_SMTP_PORT);
    UTL_SMTP.HELO(MAIL_CONN, C_SMTP_HOST);
    -- DE: REMITENTE  A DESTINATARIO
    UTL_SMTP.MAIL(MAIL_CONN, C_REMITENTE);
    UTL_SMTP.RCPT(MAIL_CONN, P_DESTINATARIO);
    -- CONTENIDO DEL CORREO
    UTL_SMTP.OPEN_DATA(MAIL_CONN);
    UTL_SMTP.WRITE_DATA(MAIL_CONN, 
      'From: ' || C_REMITENTE || CRLF ||
      'To: ' || P_DESTINATARIO || CRLF ||
      'Subject: ' || P_ASUNTO || CRLF ||
      'Content-Type: text/html; charset=UTF-8' || CRLF ||
      CRLF ||
      P_MENSAJE);
    UTL_SMTP.CLOSE_DATA(MAIL_CONN);
    UTL_SMTP.QUIT(MAIL_CONN);
    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        BEGIN
            IF MAIL_CONN IS NOT NULL THEN
                UTL_SMTP.QUIT(MAIL_CONN);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        RETURN 'ERROR: ' || SQLERRM;
END;
/

-- PROCEDIMIENTO PARA ENVIAR COMPROBANTE DE PAGO AUTOMATISADO, POR CORREGIR
CREATE OR REPLACE PROCEDURE enviar_comprobante_pago(
    p_usuario_email IN VARCHAR2,
    p_comprobante_id IN NUMBER
) AS
    v_asunto VARCHAR2(100);
    v_mensaje VARCHAR2(4000);
    v_comprobante VARCHAR2(4000);
BEGIN
    -- Obtener los datos del comprobante
    SELECT 'Comprobante de Pago #' || comprobante_id || 
           ' - Monto: ' || monto || 
           ' - Fecha: ' || TO_CHAR(fecha, 'DD/MM/YYYY')
    INTO v_comprobante
    FROM comprobantes
    WHERE comprobante_id = p_comprobante_id;

    v_asunto := 'Comprobante de Pago';
    v_mensaje := 'Estimado usuario, adjunto encontrará su comprobante de pago:' || CHR(10) || v_comprobante;


    ENVIAR_CORREO_NOTIFICADOR(
        p_destinatario => p_usuario_email,
        p_asunto    => v_asunto,
        p_mensaje    => v_mensaje
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se encontró el comprobante.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error al enviar el comprobante: ' || SQLERRM);
END enviar_comprobante_pago;
/