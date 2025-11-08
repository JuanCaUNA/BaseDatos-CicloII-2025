CREATE OR REPLACE PROCEDURE PRC_Marcar_Detalle_Notificado(
  p_detalle_id IN NUMBER
) AS
BEGIN
  -- Verificar existencia
  IF NOT EXISTS (
    SELECT 1 FROM ACS_DETALLE_PLANILLA WHERE ADP_ID = p_detalle_id
  ) THEN
    RAISE_APPLICATION_ERROR(-20020, 'No existe el detalle de planilla especificado.');
  END IF;

  -- Marcar como notificado
  UPDATE ACS_DETALLE_PLANILLA
  SET ADP_EMAIL_ENV = 1,
      ADP_FECHA_NOTIFICACION = SYSTIMESTAMP,
      ADP_FECHA_ACTUALIZACION = SYSTIMESTAMP
  WHERE ADP_ID = p_detalle_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('📨 Detalle ' || p_detalle_id || ' marcado como notificado.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20021, 'Error al marcar detalle como notificado: ' || SQLERRM);
END;
/
