-- =============================================
-- Procedimiento: PRC_Marcar_Detalle_Notificado
-- Marca un detalle de planilla como notificado
-- =============================================
CREATE OR REPLACE PROCEDURE PRC_Marcar_Detalle_Notificado(
	p_detalle_id IN NUMBER,
	p_tipo IN VARCHAR2 -- 'MEDICO' o 'ADMIN'
) AS
BEGIN
	IF p_tipo = 'MEDICO' THEN
		UPDATE ACS_DETALLE_PLANILLA_MEDICO SET DPM_ESTADO = 'NOTIFICADO' WHERE DPM_ID = p_detalle_id;
	ELSIF p_tipo = 'ADMIN' THEN
		UPDATE ACS_DETALLE_PLANILLA_ADMIN SET DPA_ESTADO = 'NOTIFICADO' WHERE DPA_ID = p_detalle_id;
	END IF;
	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
		RAISE;
END PRC_Marcar_Detalle_Notificado;
/
