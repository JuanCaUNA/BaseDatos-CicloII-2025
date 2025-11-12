CREATE OR REPLACE PROCEDURE PRC_Aplicar_Planilla(
  p_planilla_id IN NUMBER
) AS
  v_existe NUMBER;
  v_mes NUMBER;
  v_anio NUMBER;
  v_turnos_procesados NUMBER := 0;
  v_procs_procesados NUMBER := 0;
  v_escalas_procesadas NUMBER := 0;
BEGIN
  -- 1️⃣ Verificar existencia de la planilla
  SELECT COUNT(*), MAX(APL_MES), MAX(APL_ANIO)
  INTO v_existe, v_mes, v_anio
  FROM ACS_PLANILLA 
  WHERE APL_ID = p_planilla_id;

  IF v_existe = 0 THEN
    RAISE_APPLICATION_ERROR(-20010, 'No existe la planilla especificada.');
  END IF;

  DBMS_OUTPUT.PUT_LINE('========================================');
  DBMS_OUTPUT.PUT_LINE('Aplicando planilla ID: ' || p_planilla_id);
  DBMS_OUTPUT.PUT_LINE('Período: ' || v_mes || '/' || v_anio);
  DBMS_OUTPUT.PUT_LINE('========================================');

  -- 2️⃣ Marcar TURNOS como procesados (a través de ACS_TURNO_PLANILLA)
  UPDATE ACS_TURNO_PLANILLA
  SET ATRP_PROCESADO = 1,
      ATRP_FECHA_PROCESAMIENTO = SYSTIMESTAMP
  WHERE ADP_ID IN (
    SELECT ADP_ID FROM ACS_DETALLE_PLANILLA WHERE APL_ID = p_planilla_id
  )
  AND ATRP_PROCESADO = 0;
  
  v_turnos_procesados := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('✓ Turnos marcados como procesados: ' || v_turnos_procesados);

  -- 3️⃣ Marcar PROCEDIMIENTOS como procesados (a través de ACS_PROCEDIMIENTO_PLANILLA)
  UPDATE ACS_PROCEDIMIENTO_PLANILLA
  SET APRP_PROCESADO = 1,
      APRP_FECHA_PROCESAMIENTO = SYSTIMESTAMP
  WHERE ADP_ID IN (
    SELECT ADP_ID FROM ACS_DETALLE_PLANILLA WHERE APL_ID = p_planilla_id
  )
  AND APRP_PROCESADO = 0;
  
  v_procs_procesados := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('✓ Procedimientos marcados como procesados: ' || v_procs_procesados);

  -- 4️⃣ Marcar ESCALAS como procesadas
  UPDATE ACS_ESCALA_MENSUAL
  SET AEM_ESTADO = 'PROCESADA'
  WHERE AEM_MES = v_mes
    AND AEM_ANIO = v_anio
    AND AEM_ESTADO IN ('CONSTRUCCION', 'GENERADA', 'LISTA PARA PAGO');
  
  v_escalas_procesadas := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('✓ Escalas marcadas como procesadas: ' || v_escalas_procesadas);

  -- 5️⃣ Marcar detalles de planilla como procesados
  UPDATE ACS_DETALLE_PLANILLA
  SET ADP_EMAIL_ENV = 1
  WHERE APL_ID = p_planilla_id
  AND ADP_EMAIL_ENV = 0;

  -- 6️⃣ Cambiar el estado de la planilla
  UPDATE ACS_PLANILLA
  SET APL_ESTADO = 'PROCESADA',
      APL_FEC_PRO = SYSTIMESTAMP,
      APL_FECHA_ACTUALIZACION = SYSTIMESTAMP
  WHERE APL_ID = p_planilla_id;

  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('========================================');
  DBMS_OUTPUT.PUT_LINE('✅ Planilla ' || p_planilla_id || ' aplicada correctamente');
  DBMS_OUTPUT.PUT_LINE('========================================');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('✗ ERROR al aplicar planilla: ' || SQLERRM);
    RAISE_APPLICATION_ERROR(-20011, 'Error al procesar la planilla: ' || SQLERRM);
END PRC_Aplicar_Planilla;
/
