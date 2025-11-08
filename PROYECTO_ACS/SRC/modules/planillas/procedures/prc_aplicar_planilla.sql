-- =============================================
-- Procedimiento: PRC_Aplicar_Planilla
-- Marca como procesados los turnos, escalas y procedimientos involucrados en la planilla
-- Cumple con el enunciado y estructura de tablas del sistema
-- =============================================
CREATE OR REPLACE PROCEDURE PRC_Aplicar_Planilla(
	p_planilla_id IN NUMBER,
	p_tipo IN VARCHAR2 -- 'MEDICO' o 'ADMIN'
) AS
BEGIN
	IF p_tipo = 'MEDICO' THEN
		-- Marcar detalles de turnos y procedimientos como procesados
		UPDATE ACS_DETALLE_PLANILLA_MEDICO
		SET DPM_ESTADO = 'PROCESADO'
		WHERE PLM_ID = p_planilla_id;
		-- Marcar escalas mensuales como procesadas
		UPDATE ACS_ESCALA_MENSUAL
		SET AEM_ESTADO = 'PROCESADA'
		WHERE AEM_ID IN (
			SELECT adm.AEM_ID
			FROM ACS_DETALLE_MENSUAL adm
			JOIN ACS_DETALLE_PLANILLA_MEDICO dpm ON dpm.ADM_ID = adm.ADM_ID
			WHERE dpm.PLM_ID = p_planilla_id
		);
		-- Marcar procedimientos aplicados como procesados
		UPDATE ACS_PROC_APLICADO
		SET APA_ESTADO = 'PROCESADO'
		WHERE APA_ID IN (
			SELECT dpm.APA_ID FROM ACS_DETALLE_PLANILLA_MEDICO dpm WHERE dpm.PLM_ID = p_planilla_id AND dpm.APA_ID IS NOT NULL
		);
		-- Cambiar estado de la planilla 
		UPDATE ACS_PLANILLA_MEDICO SET PLM_ESTADO = 'PROCESADA' WHERE PLM_ID = p_planilla_id;
	ELSIF p_tipo = 'ADMIN' THEN
		-- Marcar detalles de planilla admin como procesados
		UPDATE ACS_DETALLE_PLANILLA_ADMIN
		SET DPA_ESTADO = 'PROCESADO'
		WHERE PLA_ID = p_planilla_id;
		-- Cambiar estado de la planilla
		UPDATE ACS_PLANILLA_ADMIN SET PLA_ESTADO = 'PROCESADA' WHERE PLA_ID = p_planilla_id;
	END IF;
	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
		RAISE;
END PRC_Aplicar_Planilla;
/
