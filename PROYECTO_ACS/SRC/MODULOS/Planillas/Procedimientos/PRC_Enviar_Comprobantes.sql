m-- =============================================
-- Procedimiento: PRC_Enviar_Comprobantes
-- Genera y envía comprobantes de pago por correo, marca detalles como notificados
-- Cumple con el enunciado y estructura de tablas del sistema
-- =============================================
CREATE OR REPLACE PROCEDURE PRC_Enviar_Comprobantes(
	p_planilla_id IN NUMBER,
	p_tipo IN VARCHAR2 -- 'MEDICO' o 'ADMIN'
) AS
	v_email VARCHAR2(200);
	v_nombre VARCHAR2(200);
	v_contenido VARCHAR2(4000);
	CURSOR c_destinatarios IS
		SELECT CASE WHEN p_tipo = 'MEDICO' THEN m.AME_ID ELSE a.AAD_ID END AS persona_id,
			   u.AUS_EMAIL, u.AUS_NOMBRE
		FROM (SELECT m.AME_ID, u.AUS_ID, u.AUS_EMAIL, u.AUS_NOMBRE FROM ACS_MEDICO m JOIN ACS_USUARIO u ON m.AUS_ID = u.AUS_ID WHERE p_tipo = 'MEDICO'
			  UNION ALL
			  SELECT a.AAD_ID, u.AUS_ID, u.AUS_EMAIL, u.AUS_NOMBRE FROM ACS_ADMINISTRATIVO a JOIN ACS_USUARIO u ON a.AUS_ID = u.AUS_ID WHERE p_tipo = 'ADMIN') u;
BEGIN
	-- Recorrer destinatarios y enviar comprobante
	FOR r_dest IN c_destinatarios LOOP
		v_email := r_dest.AUS_EMAIL;
		v_nombre := r_dest.AUS_NOMBRE;
		-- Generar contenido del comprobante (simplificado)
		v_contenido := 'Estimado ' || v_nombre || ',\nSu comprobante de pago está disponible.';
		-- Llamar procedimiento de envío de correo (debe existir PRC_Envio_Correo)
		PRC_Envio_Correo(v_email, 'Comprobante de Pago', v_contenido);
	END LOOP;
	-- Marcar detalles como notificados
	IF p_tipo = 'MEDICO' THEN
		UPDATE ACS_DETALLE_PLANILLA_MEDICO SET DPM_ESTADO = 'NOTIFICADO' WHERE PLM_ID = p_planilla_id;
		UPDATE ACS_PLANILLA_MEDICO SET PLM_ESTADO = 'NOTIFICADA' WHERE PLM_ID = p_planilla_id;
	ELSIF p_tipo = 'ADMIN' THEN
		UPDATE ACS_DETALLE_PLANILLA_ADMIN SET DPA_ESTADO = 'NOTIFICADO' WHERE PLA_ID = p_planilla_id;
		UPDATE ACS_PLANILLA_ADMIN SET PLA_ESTADO = 'NOTIFICADA' WHERE PLA_ID = p_planilla_id;
	END IF;
	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
		RAISE;
END PRC_Enviar_Comprobantes;
/
