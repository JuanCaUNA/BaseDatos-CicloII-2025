CREATE OR REPLACE PROCEDURE PRC_Aplicar_Planilla(
  p_planilla_id IN NUMBER
) AS
BEGIN
  -- 1️⃣ Verificar existencia de la planilla
  IF NOT EXISTS (
    SELECT 1 FROM ACS_PLANILLA WHERE APL_ID = p_planilla_id
  ) THEN
    RAISE_APPLICATION_ERROR(-20010, 'No existe la planilla especificada.');
  END IF;

  -- 2️⃣ Marcar todos los detalles como PROCESADOS
  UPDATE ACS_DETALLE_PLANILLA
  SET ADP_EMAIL_ENV = 1
  WHERE APL_ID = p_planilla_id;

  -- 3️⃣ Cambiar el estado de la planilla
  UPDATE ACS_PLANILLA
  SET APL_ESTADO = 'PROCESADA',
      APL_FEC_PRO = SYSTIMESTAMP,
      APL_FECHA_ACTUALIZACION = SYSTIMESTAMP
  WHERE APL_ID = p_planilla_id;

  -- 4️⃣ (Opcional) disparar movimientos automáticos
  -- ⚙️ Si tenés el trigger financiero TRG_AF_PLANILLA_PROCESADA_AU,
  --     este bloque generará los asientos al confirmar la actualización.
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ Planilla ' || p_planilla_id || ' procesada correctamente.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20011, 'Error al procesar la planilla: ' || SQLERRM);
END;
/
