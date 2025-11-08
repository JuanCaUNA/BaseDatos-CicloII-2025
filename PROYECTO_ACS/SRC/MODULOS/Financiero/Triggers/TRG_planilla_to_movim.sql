CREATE OR REPLACE TRIGGER TRG_PLANILLA_TO_MOVIM
AFTER UPDATE OF APL_ESTADO ON ACS_PLANILLA
FOR EACH ROW
WHEN (NEW.APL_ESTADO = 'PROCESADA')
DECLARE
  v_fuente VARCHAR2(20);
BEGIN
  -- Determinar fuente del movimiento según tipo de planilla
  SELECT CASE
           WHEN UPPER(t.ATP_APLICA_A) = 'MEDICO' THEN 'PLANILLA_MEDICOS'
           ELSE 'PLANILLA_ADMIN'
         END
  INTO v_fuente
  FROM ACS_TIPO_PLANILLA t
  WHERE t.ATP_ID = :NEW.ATP_ID;

  -- Insertar un movimiento por cada detalle de la planilla
  FOR r IN (
    SELECT ADP_ID, APD_NETO
    FROM ACS_DETALLE_PLANILLA
    WHERE APL_ID = :NEW.APL_ID
  ) LOOP
    INSERT INTO ACS_MOVIMIENTO_PLANILLA (
      AMP_FUENTE,
      AMP_MONTO,
      AMP_OBS,
      AMP_CALC,
      AMP_FECHA_CREACION,
      APD_ID,
      ATM_ID
    )
    VALUES (
      v_fuente,
      r.APD_NETO,
      'Movimiento generado automáticamente (planilla ' || :NEW.APL_ID || ', detalle ' || r.ADP_ID || ')',
      1,
      SYSTIMESTAMP,
      r.ADP_ID,
      1 -- por ahora dejamos ATM_ID fijo o lo ajustamos luego
    );

    -- Actualizar resumen financiero mensual
    PRC_Actualizar_Resumen_Finanzas(:NEW.APL_MES, :NEW.APL_ANIO, r.APD_NETO, v_fuente);
  END LOOP;
END;
/
