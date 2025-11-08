CREATE OR REPLACE PROCEDURE PRC_Escala_Cambiar_Estado(
  p_aem_id   IN NUMBER,
  p_estado   IN VARCHAR2
) AS
  v_estado_actual  VARCHAR2(30);
  v_cnt_turnos     NUMBER;
BEGIN
  SELECT AEM_ESTADO INTO v_estado_actual
  FROM ACS_ESCALA_MENSUAL
  WHERE AEM_ID = p_aem_id;

  -- Validaciones mínimas según transición deseada
  IF p_estado = 'VIGENTE' THEN
    NULL; -- aquí podrías validar que tenga detalles generados, etc.
  ELSIF p_estado = 'EN REVISION' THEN
    NULL;
  ELSIF p_estado = 'LISTA PARA PAGO' THEN
    -- Ejemplo: exigir al menos 1 detalle “CUMPLIDO” en el mes
    SELECT COUNT(*) INTO v_cnt_turnos
    FROM ACS_DETALLE_MENSUAL
    WHERE AEM_ID = p_aem_id
      AND NVL(ADM_ESTADO_TURNO,'CUMPLIDO') <> 'CANCELADO';
    IF v_cnt_turnos = 0 THEN
      RAISE_APPLICATION_ERROR(-20041,'Escala sin turnos válidos para lista de pago.');
    END IF;
  ELSIF p_estado = 'PROCESADA' THEN
    NULL; -- la pondremos al aplicar planilla
  ELSE
    RAISE_APPLICATION_ERROR(-20040,'Estado de escala no permitido.');
  END IF;

  UPDATE ACS_ESCALA_MENSUAL
  SET AEM_ESTADO = p_estado
  WHERE AEM_ID = p_aem_id;

  COMMIT;
END;
/
