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