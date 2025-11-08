CREATE OR REPLACE PROCEDURE PRC_GENERAR_ESCALA_MENSUAL(
  p_acm_id IN NUMBER,
  p_mes    IN NUMBER,
  p_anio   IN NUMBER
) AS
  v_aem_id   NUMBER;
  v_dias_mes NUMBER;
  v_fecha    DATE;
BEGIN
  -- Validar si ya existe escala mensual
  SELECT COUNT(*) INTO v_aem_id
  FROM ACS_ESCALA_MENSUAL
  WHERE ACM_ID = p_acm_id AND AEM_MES = p_mes AND AEM_ANIO = p_anio;

  IF v_aem_id > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Ya existe una escala mensual para ese centro, mes y año.');
  END IF;

  -- Crear encabezado
  INSERT INTO ACS_ESCALA_MENSUAL (AEM_MES, AEM_ANIO, AEM_ESTADO, ACM_ID)
  VALUES (p_mes, p_anio, 'CONSTRUCCION', p_acm_id)
  RETURNING AEM_ID INTO v_aem_id;

  -- Obtener cantidad de días del mes
  SELECT (LAST_DAY(TO_DATE('01-'||LPAD(p_mes,2,'0')||'-'||p_anio,'DD-MM-YYYY'))
         - TO_DATE('01-'||LPAD(p_mes,2,'0')||'-'||p_anio,'DD-MM-YYYY') + 1)
  INTO v_dias_mes
  FROM DUAL;

  -- Generar los días en la tabla de detalle (sin escala base)
  FOR i IN 0..v_dias_mes-1 LOOP
    v_fecha := TO_DATE('01-'||LPAD(p_mes,2,'0')||'-'||p_anio,'DD-MM-YYYY') + i;

    INSERT INTO ACS_DETALLE_MENSUAL (
      ADM_OBSERVACIONES, ADM_FECHA, ADM_ESTADO_TURNO, ADM_HR_INICIO, ADM_HR_FIN,
      ADM_ESTADO, AEM_ID, AME_ID, APM_ID, ATU_ID
    )
    SELECT
      'Generado automáticamente', v_fecha, 'CUMPLIDO', ATU_HORA_INICIO, ATU_HORA_FIN,
      'ACTIVO', v_aem_id, AME_ID, APM_ID, ATU_ID
    FROM ACS_TURNO
    WHERE ATU_ESTADO = 'ACTIVO';
  END LOOP;

  COMMIT;
END;
/
