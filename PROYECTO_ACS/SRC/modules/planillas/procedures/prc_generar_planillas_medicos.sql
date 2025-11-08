CREATE OR REPLACE PROCEDURE PRC_Generar_Planillas_Medicos(
  p_mes  IN NUMBER,
  p_anio IN NUMBER
) AS
  v_planilla_id  NUMBER;
  v_tipo_id      NUMBER;
  v_salario      NUMBER := 800000; -- salario base ejemplo
  v_deduccion    NUMBER := 0.09;   -- 9% CCSS, por ejemplo
BEGIN
  -- 1️⃣ Obtener tipo de planilla de médicos
  SELECT ATP_ID INTO v_tipo_id
  FROM ACS_TIPO_PLANILLA
  WHERE UPPER(ATP_APLICA_A) = 'MEDICO' AND ATP_ESTADO = 'ACTIVO';

  -- 2️⃣ Crear encabezado de planilla (ID autogenerado)
  INSERT INTO ACS_PLANILLA (
    APL_ANIO, APL_MES, APL_ESTADO, APL_FEC_GEN,
    APL_TOT_BRUTO, APL_TOT_DED, APL_TOT_NETO,
    APL_FECHA_CREACION, APL_FECHA_ACTUALIZACION, ATP_ID
  ) VALUES (
    p_anio, p_mes, 'GENERADA', SYSTIMESTAMP,
    0, 0, 0, SYSTIMESTAMP, SYSTIMESTAMP, v_tipo_id
  )
  RETURNING APL_ID INTO v_planilla_id;

  -- 3️⃣ Insertar detalle por cada médico activo
  FOR reg IN (
    SELECT p.AUS_ID
    FROM ACS_PERSONAL_TIPO_PLANILLA p
    WHERE p.ATP_ID = v_tipo_id AND p.APTP_ACTIVO = 1
  ) LOOP
    INSERT INTO ACS_DETALLE_PLANILLA (
      ADP_TIPO_PERSONA, ADP_SALARIO_BASE, ADP_BRUTO, ADP_DED,
      APD_NETO, ADP_EMAIL_ENV, ADP_FECHA_CREACION, ADP_FECHA_ACTUALIZACION,
      APL_ID, AUS_ID
    ) VALUES (
      'MEDICO', v_salario, v_salario, v_salario * v_deduccion,
      v_salario - (v_salario * v_deduccion), 0, SYSTIMESTAMP, SYSTIMESTAMP,
      v_planilla_id, reg.AUS_ID
    );
  END LOOP;

  -- 4️⃣ Actualizar totales de la planilla
  UPDATE ACS_PLANILLA p SET
    (APL_TOT_BRUTO, APL_TOT_DED, APL_TOT_NETO) = (
      SELECT NVL(SUM(ADP_BRUTO),0), NVL(SUM(ADP_DED),0), NVL(SUM(APD_NETO),0)
      FROM ACS_DETALLE_PLANILLA d
      WHERE d.APL_ID = p.APL_ID
    )
  WHERE p.APL_ID = v_planilla_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ Planilla de médicos generada correctamente.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20001, 'Error al generar planilla de médicos: ' || SQLERRM);
END;
/
