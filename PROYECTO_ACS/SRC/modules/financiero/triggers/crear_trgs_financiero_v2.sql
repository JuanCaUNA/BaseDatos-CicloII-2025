-- =================================================================
-- TRIGGERS DEL MÓDULO FINANCIERO
-- Mantienen actualizadas automáticamente las tablas de resumen
-- =================================================================

-- Trigger 1: Registra asientos cuando se procesa una planilla
CREATE OR REPLACE TRIGGER TRG_AF_PLANILLA_PROCESADA_AU
AFTER UPDATE OF APL_ESTADO ON ACS_PLANILLA
FOR EACH ROW
DECLARE
  V_MONTO NUMBER;
  V_FUENTE VARCHAR2(50);
  V_APLICA VARCHAR2(20);
BEGIN
  -- Solo actuar cuando la planilla cambia a estado PROCESADA
  IF :NEW.APL_ESTADO = 'PROCESADA' THEN
    -- Obtener el total neto de la planilla
    SELECT NVL(SUM(APD_NETO),0) 
    INTO V_MONTO
    FROM ACS_DETALLE_PLANILLA
    WHERE APL_ID = :NEW.APL_ID;

    -- Determinar si es planilla médica o administrativa
    SELECT TP.ATP_APLICA_A 
    INTO V_APLICA
    FROM ACS_TIPO_PLANILLA TP
    WHERE TP.ATP_ID = :NEW.ATP_ID;

    V_FUENTE := CASE 
                  WHEN V_APLICA = 'ADMINISTRATIVO' THEN 'PLANILLA_ADMINISTRATIVA' 
                  ELSE 'PLANILLA_MEDICA' 
                END;

    -- Registrar el gasto (lo que pagamos al personal)
    INSERT INTO ACS_ASIENTO_FINANCIERO (
      AAF_TIPO, 
      AAF_FUENTE, 
      AAF_MONTO, 
      AAF_PERIODO_ANIO, 
      AAF_PERIODO_MES, 
      ACM_ID, 
      AAF_FECHA,
      AAF_FECHA_CREACION,
      AAF_FECHA_ACTUALIZACION
    )
    VALUES (
      'GASTO', 
      V_FUENTE, 
      V_MONTO, 
      :NEW.APL_ANIO, 
      :NEW.APL_MES, 
      NULL,  -- Gastos generales, no asociados a centro específico
      SYSTIMESTAMP,
      SYSTIMESTAMP,
      SYSTIMESTAMP
    );
  END IF;
END;
/

-- Trigger 2: Actualiza resumen mensual general cuando se inserta asiento
CREATE OR REPLACE TRIGGER TRG_RESUMEN_FIN_MENSUAL_AI
AFTER INSERT ON ACS_ASIENTO_FINANCIERO
FOR EACH ROW
BEGIN
  MERGE INTO ACS_RESUMEN_FIN_MENSUAL T
  USING (
    SELECT 
      :NEW.AAF_PERIODO_ANIO AS ANIO, 
      :NEW.AAF_PERIODO_MES AS MES 
    FROM DUAL
  ) S
  ON (T.ARM_PERIODO_ANIO = S.ANIO AND T.ARM_PERIODO_MES = S.MES)
  WHEN NOT MATCHED THEN
    INSERT (
      ARM_PERIODO_ANIO, 
      ARM_PERIODO_MES, 
      ARM_INGRESOS, 
      ARM_GASTOS, 
      ARM_UTILIDAD,
      ARM_FECHA_CREACION,
      ARM_FECHA_ACTUALIZACION
    )
    VALUES (
      S.ANIO, 
      S.MES, 
      0, 
      0, 
      0,
      SYSTIMESTAMP,
      SYSTIMESTAMP
    )
  WHEN MATCHED THEN
    UPDATE SET
      ARM_INGRESOS = NVL(ARM_INGRESOS,0) + CASE WHEN :NEW.AAF_TIPO='INGRESO' THEN :NEW.AAF_MONTO ELSE 0 END,
      ARM_GASTOS   = NVL(ARM_GASTOS,0)   + CASE WHEN :NEW.AAF_TIPO='GASTO'   THEN :NEW.AAF_MONTO ELSE 0 END,
      ARM_UTILIDAD = (NVL(ARM_INGRESOS,0) + CASE WHEN :NEW.AAF_TIPO='INGRESO' THEN :NEW.AAF_MONTO ELSE 0 END)
                   - (NVL(ARM_GASTOS,0)   + CASE WHEN :NEW.AAF_TIPO='GASTO'   THEN :NEW.AAF_MONTO ELSE 0 END),
      ARM_FECHA_ACTUALIZACION = SYSTIMESTAMP;
END;
/

-- Trigger 3: Actualiza resumen por centro cuando se inserta asiento con centro
CREATE OR REPLACE TRIGGER TRG_RESUMEN_FIN_CENTRO_AI
AFTER INSERT ON ACS_ASIENTO_FINANCIERO
FOR EACH ROW
BEGIN
  -- Solo procesar si el asiento tiene un centro asociado
  IF :NEW.ACM_ID IS NOT NULL THEN
    MERGE INTO ACS_RESUMEN_FIN_CENTRO_MES T
    USING (
      SELECT 
        :NEW.ACM_ID AS ACM_ID, 
        :NEW.AAF_PERIODO_ANIO AS ANIO, 
        :NEW.AAF_PERIODO_MES AS MES 
      FROM DUAL
    ) S
    ON (T.ACM_ID = S.ACM_ID AND T.ARCM_PERIODO_ANIO = S.ANIO AND T.ARCM_PERIODO_MES = S.MES)
    WHEN NOT MATCHED THEN
      INSERT (
        ACM_ID, 
        ARCM_PERIODO_ANIO, 
        ARCM_PERIODO_MES, 
        ARCM_INGRESOS, 
        ARCM_GASTOS, 
        ARCM_UTILIDAD,
        ARCM_FECHA_CREACION,
        ARCM_FECHA_ACTUALIZACION
      )
      VALUES (
        S.ACM_ID, 
        S.ANIO, 
        S.MES, 
        0, 
        0, 
        0,
        SYSTIMESTAMP,
        SYSTIMESTAMP
      )
    WHEN MATCHED THEN
      UPDATE SET
        ARCM_INGRESOS = NVL(ARCM_INGRESOS,0) + CASE WHEN :NEW.AAF_TIPO='INGRESO' THEN :NEW.AAF_MONTO ELSE 0 END,
        ARCM_GASTOS   = NVL(ARCM_GASTOS,0)   + CASE WHEN :NEW.AAF_TIPO='GASTO'   THEN :NEW.AAF_MONTO ELSE 0 END,
        ARCM_UTILIDAD = (NVL(ARCM_INGRESOS,0) + CASE WHEN :NEW.AAF_TIPO='INGRESO' THEN :NEW.AAF_MONTO ELSE 0 END)
                       - (NVL(ARCM_GASTOS,0)   + CASE WHEN :NEW.AAF_TIPO='GASTO'   THEN :NEW.AAF_MONTO ELSE 0 END),
        ARCM_FECHA_ACTUALIZACION = SYSTIMESTAMP;
  END IF;
END;
/

PROMPT Triggers financieros creados exitosamente!
PROMPT - TRG_AF_PLANILLA_PROCESADA_AU: Registra gastos de planillas procesadas
PROMPT - TRG_RESUMEN_FIN_MENSUAL_AI: Actualiza resumen general mensual
PROMPT - TRG_RESUMEN_FIN_CENTRO_AI: Actualiza resumen por centro

EXIT;
