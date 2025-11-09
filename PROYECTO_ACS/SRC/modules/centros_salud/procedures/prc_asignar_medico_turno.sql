-- =============================================================
-- Procedimiento: PRC_Asignar_Medico_Turno
-- Descripción: Asigna o reasigna un médico a un turno específico de la escala mensual
-- Cumple con el enunciado: permite cambios de médico, modificación de turnos, etc.
-- Parámetros: p_adm_id (detalle mensual), p_ame_id (nuevo médico)
-- =============================================================
CREATE OR REPLACE PROCEDURE PRC_Asignar_Medico_Turno(
	p_adm_id IN NUMBER,
	p_ame_id IN NUMBER
) AS
	v_estado_turno VARCHAR2(20);
BEGIN
	-- Validar que el detalle mensual existe
	SELECT ADM_ESTADO_TURNO INTO v_estado_turno
	  FROM ACS_DETALLE_MENSUAL
	 WHERE ADM_ID = p_adm_id;

	-- Solo permite reasignar si el turno no está cancelado
	IF v_estado_turno = 'CANCELADO' THEN
		RAISE_APPLICATION_ERROR(-20010, 'No se puede reasignar un turno cancelado.');
	END IF;

	-- Actualizar el médico asignado y marcar como REEMPLAZADO
	UPDATE ACS_DETALLE_MENSUAL
	   SET AME_ID = p_ame_id,
		   ADM_ESTADO_TURNO = 'REEMPLAZADO'
	 WHERE ADM_ID = p_adm_id;

	COMMIT;
END;
/ 
