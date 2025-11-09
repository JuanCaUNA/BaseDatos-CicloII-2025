CREATE OR REPLACE PROCEDURE PRC_Actualizar_Resumen_Finanzas(
  p_mes IN NUMBER,
  p_anio IN NUMBER,
  p_monto IN NUMBER,
  p_fuente IN VARCHAR2
) AS
  v_existente NUMBER;
  v_ingresos  NUMBER := 0;
  v_gastos    NUMBER := 0;
BEGIN
  -- Definir si el monto es ingreso o gasto
  IF p_fuente = 'PLANILLA_MEDICOS' OR p_fuente = 'PLANILLA_ADMIN' THEN
    v_gastos := p_monto;
  ELSE
    v_ingresos := p_monto;
  END IF;

  -- Verificar si ya existe el registro mensual
  SELECT COUNT(*) INTO v_existente
  FROM ACS_RESUMEN_FIN_MENSUAL
  WHERE ARM_PERIODO_ANIO = p_anio
    AND ARM_PERIODO_MES  = p_mes;

  IF v_existente = 0 THEN
    INSERT INTO ACS_RESUMEN_FIN_MENSUAL (
      ARM_PERIODO_ANIO, ARM_PERIODO_MES, ARM_INGRESOS, ARM_GASTOS, ARM_UTILIDAD,
      ARM_FECHA_CREACION, ARM_FECHA_ACTUALIZACION
    )
    VALUES (
      p_anio, p_mes,
      v_ingresos, v_gastos,
      v_ingresos - v_gastos,
      SYSTIMESTAMP, SYSTIMESTAMP
    );
  ELSE
    UPDATE ACS_RESUMEN_FIN_MENSUAL
       SET ARM_INGRESOS = ARM_INGRESOS + v_ingresos,
           ARM_GASTOS    = ARM_GASTOS + v_gastos,
           ARM_UTILIDAD  = (ARM_INGRESOS + v_ingresos) - (ARM_GASTOS + v_gastos),
           ARM_FECHA_ACTUALIZACION = SYSTIMESTAMP
     WHERE ARM_PERIODO_ANIO = p_anio
       AND ARM_PERIODO_MES  = p_mes;
  END IF;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/

