-- =============================================
-- Procedimiento: PRC_ACTUALIZAR_RESUMEN_FINANZAS
-- Actualiza el resumen financiero mensual (ACS_RESUMEN_FIN_MENSUAL)
-- Clasifica montos como ingresos o gastos según la fuente
-- Es llamado automáticamente por el trigger TRG_PLANILLA_TO_MOVIM
-- Fecha: 2025-11-09
-- =============================================
CREATE OR REPLACE PROCEDURE PRC_ACTUALIZAR_RESUMEN_FINANZAS (
  p_mes IN NUMBER,
  p_anio IN NUMBER,
  p_monto IN NUMBER,
  p_fuente IN VARCHAR2
) AS
  v_existente NUMBER;
  v_ingresos  NUMBER := 0;
  v_gastos    NUMBER := 0;
BEGIN
  -- Definir si el monto es ingreso o gasto según la fuente
  -- Fuentes de GASTO: Planillas (pagos a personal)
  -- Fuentes de INGRESO: Turnos, Procedimientos (cobros a centros de salud)
  IF p_fuente IN ('PLANILLA_MEDICOS', 'PLANILLA_ADMIN') THEN
    v_gastos := p_monto;
  ELSE
    -- Asumir que otras fuentes son ingresos
    v_ingresos := p_monto;
  END IF;

  -- Verificar si ya existe el registro mensual
  SELECT COUNT(*) INTO v_existente
  FROM ACS_RESUMEN_FIN_MENSUAL
  WHERE ARM_PERIODO_ANIO = p_anio
    AND ARM_PERIODO_MES  = p_mes;

  IF v_existente = 0 THEN
    -- Crear nuevo registro para el mes
    INSERT INTO ACS_RESUMEN_FIN_MENSUAL (
      ARM_PERIODO_ANIO,
      ARM_PERIODO_MES,
      ARM_INGRESOS,
      ARM_GASTOS,
      ARM_UTILIDAD,
      ARM_FECHA_CREACION,
      ARM_FECHA_ACTUALIZACION
    )
    VALUES (
      p_anio,
      p_mes,
      v_ingresos,
      v_gastos,
      v_ingresos - v_gastos,
      SYSTIMESTAMP,
      SYSTIMESTAMP
    );
  ELSE
    -- Actualizar registro existente acumulando valores
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
    RAISE_APPLICATION_ERROR(-20060, 'Error al actualizar resumen financiero: ' || SQLERRM);
END PRC_ACTUALIZAR_RESUMEN_FINANZAS;
/
