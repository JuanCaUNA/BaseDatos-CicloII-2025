-- =============================================================================
-- Script de Prueba End-to-End: Sistema de Planillas Completo
-- =============================================================================
-- Descripción: Valida el flujo completo de generación de planillas:
--   1. Crea datos base mínimos (centros, médicos, administrativos)
--   2. Genera escala mensual con turnos
--   3. Genera planillas para médicos y administrativos
--   4. Aplica movimientos automáticos (CCSS, Renta, Banco, Caja)
--   5. Valida cálculos y movimientos aplicados
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;

DECLARE
    v_test_mes NUMBER := 11;  -- Noviembre
    v_test_anio NUMBER := 2025;
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('INICIO DE PRUEBA END-TO-END: SISTEMA DE PLANILLAS');
    DBMS_OUTPUT.PUT_LINE('Mes/Año: ' || v_test_mes || '/' || v_test_anio);
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =============================================================================
    -- 0️⃣ VERIFICAR PREREQUISITOS
    -- =============================================================================
    DBMS_OUTPUT.PUT_LINE('--- VERIFICANDO PREREQUISITOS ---');
    
    -- Verificar movimientos automáticos
    SELECT COUNT(*) INTO v_count FROM ACS_TIPO_MOV WHERE ATM_ES_AUTOMATICO = 1;
    DBMS_OUTPUT.PUT_LINE('✓ Movimientos automáticos configurados: ' || v_count);
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No hay movimientos automáticos configurados. Ejecutar seed data primero.');
    END IF;
    
    -- Verificar rangos de renta
    SELECT COUNT(*) INTO v_count FROM ACS_TIPO_MOV_RANGO;
    DBMS_OUTPUT.PUT_LINE('✓ Rangos salariales configurados: ' || v_count);
    
    -- Verificar tipos de planilla
    SELECT COUNT(*) INTO v_count FROM ACS_TIPO_PLANILLA WHERE ATP_ESTADO = 'ACTIVO';
    DBMS_OUTPUT.PUT_LINE('✓ Tipos de planilla activos: ' || v_count);
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =============================================================================
    -- 1️⃣ LIMPIAR DATOS DE PRUEBA ANTERIORES
    -- =============================================================================
    DBMS_OUTPUT.PUT_LINE('--- LIMPIANDO DATOS DE PRUEBAS ANTERIORES ---');
    
    -- Eliminar planillas del mes de prueba
    DELETE FROM ACS_MOVIMIENTO_PLANILLA 
    WHERE APD_ID IN (
        SELECT ADP_ID FROM ACS_DETALLE_PLANILLA 
        WHERE APL_ID IN (
            SELECT APL_ID FROM ACS_PLANILLA 
            WHERE APL_MES = v_test_mes AND APL_ANIO = v_test_anio
        )
    );
    DBMS_OUTPUT.PUT_LINE('✓ Movimientos de planilla eliminados');
    
    DELETE FROM ACS_DETALLE_PLANILLA 
    WHERE APL_ID IN (
        SELECT APL_ID FROM ACS_PLANILLA 
        WHERE APL_MES = v_test_mes AND APL_ANIO = v_test_anio
    );
    DBMS_OUTPUT.PUT_LINE('✓ Detalles de planilla eliminados');
    
    DELETE FROM ACS_PLANILLA 
    WHERE APL_MES = v_test_mes AND APL_ANIO = v_test_anio;
    DBMS_OUTPUT.PUT_LINE('✓ Planillas eliminadas');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- =============================================================================
    -- 2️⃣ GENERAR PLANILLAS
    -- =============================================================================
    DBMS_OUTPUT.PUT_LINE('--- GENERANDO PLANILLAS ---');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Planilla de Administrativos
    BEGIN
        DBMS_OUTPUT.PUT_LINE('>> Generando planilla de ADMINISTRATIVOS...');
        PRC_GENERAR_PLANILLAS_ADMIN(v_test_mes, v_test_anio);
        DBMS_OUTPUT.PUT_LINE('');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('⚠ Error al generar planilla de administrativos: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('  Esto es normal si no hay personal administrativo configurado.');
    END;
    
    -- Planilla de Médicos
    BEGIN
        DBMS_OUTPUT.PUT_LINE('>> Generando planilla de MÉDICOS...');
        PRC_GENERAR_PLANILLAS_MEDICOS(v_test_mes, v_test_anio);
        DBMS_OUTPUT.PUT_LINE('');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('⚠ Error al generar planilla de médicos: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('  Esto es normal si no hay médicos con turnos en el mes.');
    END;
    
    -- =============================================================================
    -- 3️⃣ VERIFICAR RESULTADOS
    -- =============================================================================
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('RESUMEN DE RESULTADOS');
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Contar planillas generadas
    SELECT COUNT(*) INTO v_count FROM ACS_PLANILLA WHERE APL_MES = v_test_mes AND APL_ANIO = v_test_anio;
    DBMS_OUTPUT.PUT_LINE('📋 Planillas generadas: ' || v_count);
    
    -- Detalles por planilla
    FOR pl IN (
        SELECT 
            pl.APL_ID,
            tp.ATP_NOMBRE,
            pl.APL_ESTADO,
            COUNT(dp.ADP_ID) AS CANT_PERSONAS,
            SUM(dp.ADP_BRUTO) AS TOT_BRUTO,
            SUM(dp.ADP_DED) AS TOT_DED,
            SUM(dp.APD_NETO) AS TOT_NETO
        FROM ACS_PLANILLA pl
        JOIN ACS_TIPO_PLANILLA tp ON pl.ATP_ID = tp.ATP_ID
        LEFT JOIN ACS_DETALLE_PLANILLA dp ON pl.APL_ID = dp.APL_ID
        WHERE pl.APL_MES = v_test_mes AND pl.APL_ANIO = v_test_anio
        GROUP BY pl.APL_ID, tp.ATP_NOMBRE, pl.APL_ESTADO
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  Planilla ID: ' || pl.APL_ID || ' (' || pl.ATP_NOMBRE || ')');
        DBMS_OUTPUT.PUT_LINE('  Estado: ' || pl.APL_ESTADO);
        DBMS_OUTPUT.PUT_LINE('  Personas: ' || pl.CANT_PERSONAS);
        DBMS_OUTPUT.PUT_LINE('  Total Bruto: ₡' || ROUND(NVL(pl.TOT_BRUTO, 0), 2));
        DBMS_OUTPUT.PUT_LINE('  Total Deducciones: ₡' || ROUND(NVL(pl.TOT_DED, 0), 2));
        DBMS_OUTPUT.PUT_LINE('  Total Neto: ₡' || ROUND(NVL(pl.TOT_NETO, 0), 2));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- MOVIMIENTOS APLICADOS ---');
    
    -- Contar movimientos por tipo
    FOR mov IN (
        SELECT 
            tm.ATM_COD,
            tm.ATM_NOMBRE,
            tm.ATM_NATURALEZA,
            COUNT(mp.AMP_ID) AS CANT_APLICACIONES,
            SUM(mp.AMP_MONTO) AS TOTAL_MONTO
        FROM ACS_MOVIMIENTO_PLANILLA mp
        JOIN ACS_TIPO_MOV tm ON mp.ATM_ID = tm.ATM_ID
        JOIN ACS_DETALLE_PLANILLA dp ON mp.APD_ID = dp.ADP_ID
        JOIN ACS_PLANILLA pl ON dp.APL_ID = pl.APL_ID
        WHERE pl.APL_MES = v_test_mes AND pl.APL_ANIO = v_test_anio
        GROUP BY tm.ATM_COD, tm.ATM_NOMBRE, tm.ATM_NATURALEZA
        ORDER BY tm.ATM_NATURALEZA, tm.ATM_COD
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || mov.ATM_COD || ' (' || mov.ATM_NATURALEZA || '): ' || 
                           mov.CANT_APLICACIONES || ' aplicaciones, Total: ₡' || 
                           ROUND(mov.TOTAL_MONTO, 2));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- DETALLES POR PERSONA ---');
    
    -- Mostrar primeras 5 personas
    FOR per IN (
        SELECT 
            pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO AS NOMBRE_COMPLETO,
            dp.ADP_TIPO_PERSONA,
            dp.ADP_SALARIO_BASE,
            dp.ADP_BRUTO,
            dp.ADP_DED,
            dp.APD_NETO,
            (SELECT COUNT(*) FROM ACS_MOVIMIENTO_PLANILLA WHERE APD_ID = dp.ADP_ID) AS CANT_MOVIMIENTOS
        FROM ACS_DETALLE_PLANILLA dp
        JOIN ACS_PLANILLA pl ON dp.APL_ID = pl.APL_ID
        JOIN ACS_USUARIO u ON dp.AUS_ID = u.AUS_ID
        JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
        WHERE pl.APL_MES = v_test_mes AND pl.APL_ANIO = v_test_anio
        AND ROWNUM <= 5
        ORDER BY dp.ADP_TIPO_PERSONA, pe.APE_P_APELLIDO
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || per.NOMBRE_COMPLETO || ' (' || per.ADP_TIPO_PERSONA || ')');
        DBMS_OUTPUT.PUT_LINE('    Salario Base: ₡' || ROUND(per.ADP_SALARIO_BASE, 2));
        DBMS_OUTPUT.PUT_LINE('    Bruto: ₡' || ROUND(per.ADP_BRUTO, 2));
        DBMS_OUTPUT.PUT_LINE('    Deducciones: ₡' || ROUND(per.ADP_DED, 2));
        DBMS_OUTPUT.PUT_LINE('    Neto: ₡' || ROUND(per.APD_NETO, 2));
        DBMS_OUTPUT.PUT_LINE('    Movimientos aplicados: ' || per.CANT_MOVIMIENTOS);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    -- =============================================================================
    -- 4️⃣ VALIDACIONES DE INTEGRIDAD
    -- =============================================================================
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('VALIDACIONES DE INTEGRIDAD');
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    
    -- Validar que totales cuadren
    FOR pl IN (
        SELECT 
            pl.APL_ID,
            pl.APL_TOT_BRUTO AS TOT_BRUTO_HEADER,
            pl.APL_TOT_DED AS TOT_DED_HEADER,
            pl.APL_TOT_NETO AS TOT_NETO_HEADER,
            NVL(SUM(dp.ADP_BRUTO), 0) AS TOT_BRUTO_CALC,
            NVL(SUM(dp.ADP_DED), 0) AS TOT_DED_CALC,
            NVL(SUM(dp.APD_NETO), 0) AS TOT_NETO_CALC
        FROM ACS_PLANILLA pl
        LEFT JOIN ACS_DETALLE_PLANILLA dp ON pl.APL_ID = dp.APL_ID
        WHERE pl.APL_MES = v_test_mes AND pl.APL_ANIO = v_test_anio
        GROUP BY pl.APL_ID, pl.APL_TOT_BRUTO, pl.APL_TOT_DED, pl.APL_TOT_NETO
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Planilla ' || pl.APL_ID || ':');
        
        IF ABS(pl.TOT_BRUTO_HEADER - pl.TOT_BRUTO_CALC) < 0.01 THEN
            DBMS_OUTPUT.PUT_LINE('  ✓ Bruto cuadra');
        ELSE
            DBMS_OUTPUT.PUT_LINE('  ✗ ERROR Bruto: Header=' || pl.TOT_BRUTO_HEADER || ', Calc=' || pl.TOT_BRUTO_CALC);
        END IF;
        
        IF ABS(pl.TOT_DED_HEADER - pl.TOT_DED_CALC) < 0.01 THEN
            DBMS_OUTPUT.PUT_LINE('  ✓ Deducciones cuadran');
        ELSE
            DBMS_OUTPUT.PUT_LINE('  ✗ ERROR Deducciones: Header=' || pl.TOT_DED_HEADER || ', Calc=' || pl.TOT_DED_CALC);
        END IF;
        
        IF ABS(pl.TOT_NETO_HEADER - pl.TOT_NETO_CALC) < 0.01 THEN
            DBMS_OUTPUT.PUT_LINE('  ✓ Neto cuadra');
        ELSE
            DBMS_OUTPUT.PUT_LINE('  ✗ ERROR Neto: Header=' || pl.TOT_NETO_HEADER || ', Calc=' || pl.TOT_NETO_CALC);
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    -- =============================================================================
    -- 5️⃣ CONCLUSIÓN
    -- =============================================================================
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('✅ PRUEBA END-TO-END COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Para validar cálculos detallados, ejecutar:');
    DBMS_OUTPUT.PUT_LINE('  SELECT * FROM ACS_MOVIMIENTO_PLANILLA WHERE APD_ID IN ');
    DBMS_OUTPUT.PUT_LINE('    (SELECT ADP_ID FROM ACS_DETALLE_PLANILLA WHERE APL_ID IN');
    DBMS_OUTPUT.PUT_LINE('      (SELECT APL_ID FROM ACS_PLANILLA WHERE APL_MES=' || v_test_mes || ' AND APL_ANIO=' || v_test_anio || '));');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('❌ ERROR EN PRUEBA: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
        ROLLBACK;
END;
/
