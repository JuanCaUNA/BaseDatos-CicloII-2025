-- =============================================================================
-- Procedimiento: PRC_GENERAR_PLANILLAS_MEDICOS (Versión 2 - COMPLETA)
-- =============================================================================
-- Descripción: Genera planillas mensuales para médicos con:
--   1. Cálculo de bruto desde turnos trabajados (ATU_TIPO_PAGO: HORAS/TURNO)
--   2. Inclusión de procedimientos aplicados
--   3. Aplicación automática de movimientos (CCSS, Renta, etc.)
--   4. Registro detallado en ACS_MOVIMIENTO_PLANILLA
-- =============================================================================
-- Parámetros:
--   p_mes:  Mes de la planilla (1-12)
--   p_anio: Año de la planilla
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_GENERAR_PLANILLAS_MEDICOS(
    p_mes  IN NUMBER,
    p_anio IN NUMBER
) AS
    v_planilla_id  NUMBER;
    v_tipo_id      NUMBER;
    v_detalle_id   NUMBER;
    
    -- Totales del médico
    v_turnos       NUMBER;
    v_procedimientos NUMBER;
    v_bruto        NUMBER;
    v_deducciones  NUMBER;
    v_neto         NUMBER;
    
    -- Para movimientos automáticos
    v_monto_movimiento NUMBER;
    
    -- Contadores
    v_count_medicos NUMBER := 0;
    v_count_detalles NUMBER := 0;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Generando planilla de médicos: ' || p_mes || '/' || p_anio);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- 1️⃣ Obtener tipo de planilla de médicos
    BEGIN
        SELECT ATP_ID INTO v_tipo_id
        FROM ACS_TIPO_PLANILLA
        WHERE UPPER(ATP_APLICA_A) = 'MEDICOS' 
          AND ATP_ESTADO = 'ACTIVO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'No existe tipo de planilla para MEDICOS');
    END;
    
    -- 2️⃣ Crear encabezado de planilla
    INSERT INTO ACS_PLANILLA (
        APL_ANIO, APL_MES, APL_ESTADO, APL_FEC_GEN,
        APL_TOT_BRUTO, APL_TOT_DED, APL_TOT_NETO,
        APL_FECHA_CREACION, APL_FECHA_ACTUALIZACION, ATP_ID
    ) VALUES (
        p_anio, p_mes, 'GENERADA', SYSTIMESTAMP,
        0, 0, 0, SYSTIMESTAMP, SYSTIMESTAMP, v_tipo_id
    )
    RETURNING APL_ID INTO v_planilla_id;
    
    DBMS_OUTPUT.PUT_LINE('Planilla creada con ID: ' || v_planilla_id);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- 3️⃣ Procesar cada médico asignado al tipo de planilla
    FOR medico IN (
        SELECT p.AUS_ID, pe.APE_NOMBRE, pe.APE_P_APELLIDO, pe.APE_S_APELLIDO
        FROM ACS_PERSONAL_TIPO_PLANILLA p
        JOIN ACS_USUARIO u ON p.AUS_ID = u.AUS_ID
        JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
        WHERE p.ATP_ID = v_tipo_id 
          AND p.APTP_ACTIVO = 1
        ORDER BY pe.APE_P_APELLIDO, pe.APE_NOMBRE
    ) LOOP
        v_count_medicos := v_count_medicos + 1;
        
        -- A) Calcular pago por TURNOS trabajados
        v_turnos := 0;
        
        FOR turno IN (
            SELECT 
                dm.ADM_ID,
                t.ATU_TIPO_PAGO,
                t.ATU_PAGO,
                CASE 
                    WHEN t.ATU_TIPO_PAGO = 'HORAS' THEN
                        -- Calcular horas trabajadas
                        ROUND(
                            (CAST(dm.ADM_HR_FIN AS DATE) - CAST(dm.ADM_HR_INICIO AS DATE)) * 24,
                            2
                        ) * t.ATU_PAGO
                    WHEN t.ATU_TIPO_PAGO = 'TURNO' THEN
                        -- Pago fijo por turno completo
                        t.ATU_PAGO
                    ELSE 0
                END AS PAGO_CALCULADO
            FROM ACS_DETALLE_MENSUAL dm
            JOIN ACS_TURNO t ON dm.ATU_ID = t.ATU_ID
            JOIN ACS_ESCALA_MENSUAL em ON dm.AEM_ID = em.AEM_ID
            WHERE em.AEM_MES = p_mes 
              AND em.AEM_ANIO = p_anio
              AND dm.APM_ID = medico.AUS_ID
              AND dm.ADM_ESTADO_TURNO = 'CUMPLIDO'
        ) LOOP
            v_turnos := v_turnos + turno.PAGO_CALCULADO;
        END LOOP;
        
        -- B) Calcular pago por PROCEDIMIENTOS aplicados
        v_procedimientos := 0;
        
        BEGIN
            SELECT NVL(SUM(pa.APA_PAGO), 0)
            INTO v_procedimientos
            FROM ACS_PROC_APLICADO pa
            JOIN ACS_DETALLE_MENSUAL dm ON pa.AME_ID = dm.AME_ID
            JOIN ACS_ESCALA_MENSUAL em ON dm.AEM_ID = em.AEM_ID
            WHERE em.AEM_MES = p_mes
              AND em.AEM_ANIO = p_anio
              AND dm.APM_ID = medico.AUS_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_procedimientos := 0;
        END;
        
        -- C) Calcular BRUTO total (turnos + procedimientos)
        v_bruto := v_turnos + v_procedimientos;
        
        -- Si el médico no trabajó este mes, omitir
        IF v_bruto <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('  ⚠ ' || medico.APE_NOMBRE || ' ' || medico.APE_P_APELLIDO || 
                               ' no tiene turnos ni procedimientos este mes.');
            CONTINUE;
        END IF;
        
        -- D) Crear detalle de planilla
        INSERT INTO ACS_DETALLE_PLANILLA (
            ADP_TIPO_PERSONA, ADP_SALARIO_BASE, ADP_BRUTO, ADP_DED,
            APD_NETO, ADP_EMAIL_ENV, ADP_FECHA_CREACION, ADP_FECHA_ACTUALIZACION,
            APL_ID, AUS_ID
        ) VALUES (
            'MEDICO', v_bruto, v_bruto, 0,
            v_bruto, 0, SYSTIMESTAMP, SYSTIMESTAMP, v_planilla_id, medico.AUS_ID
        )
        RETURNING ADP_ID INTO v_detalle_id;
        
        v_count_detalles := v_count_detalles + 1;
        
        -- E) Aplicar MOVIMIENTOS AUTOMÁTICOS (deducciones)
        v_deducciones := 0;
        
        FOR mov IN (
            SELECT ATM_ID, ATM_COD, ATM_NOMBRE, ATM_NATURALEZA
            FROM ACS_TIPO_MOV
            WHERE ATM_ES_AUTOMATICO = 1
              AND ATM_APLICA_A IN ('MEDICO', 'AMBOS')
              AND ATM_ESTADO = 'ACTIVO'
            ORDER BY ATM_PRIORIDAD
        ) LOOP
            -- Calcular monto del movimiento usando la función
            v_monto_movimiento := FUN_CALCULAR_MOVIMIENTO(mov.ATM_ID, v_bruto);
            
            -- Solo insertar si hay monto
            IF v_monto_movimiento > 0 THEN
                -- Registrar movimiento aplicado
                INSERT INTO ACS_MOVIMIENTO_PLANILLA (
                    AMP_FUENTE, AMP_MONTO, AMP_OBS, AMP_CALC,
                    AMP_FECHA_CREACION, APD_ID, ATM_ID
                ) VALUES (
                    'AUTOMATICO',
                    v_monto_movimiento,
                    'Aplicado automáticamente: ' || mov.ATM_NOMBRE,
                    v_bruto,  -- Base de cálculo
                    SYSTIMESTAMP,
                    v_detalle_id,
                    mov.ATM_ID
                );
                
                -- Acumular deducciones
                IF mov.ATM_NATURALEZA = 'DEDUCCION' THEN
                    v_deducciones := v_deducciones + v_monto_movimiento;
                END IF;
            END IF;
        END LOOP;
        
        -- F) Calcular NETO y actualizar detalle
        v_neto := v_bruto - v_deducciones;
        
        UPDATE ACS_DETALLE_PLANILLA
        SET ADP_DED = v_deducciones,
            APD_NETO = v_neto,
            ADP_FECHA_ACTUALIZACION = SYSTIMESTAMP
        WHERE ADP_ID = v_detalle_id;
        
        DBMS_OUTPUT.PUT_LINE('  ✓ ' || medico.APE_NOMBRE || ' ' || medico.APE_P_APELLIDO || 
                           ' - Bruto: ₡' || ROUND(v_bruto, 2) || 
                           ' | Ded: ₡' || ROUND(v_deducciones, 2) ||
                           ' | Neto: ₡' || ROUND(v_neto, 2));
        
    END LOOP;
    
    -- 4️⃣ Actualizar totales de la planilla
    UPDATE ACS_PLANILLA p 
    SET (APL_TOT_BRUTO, APL_TOT_DED, APL_TOT_NETO) = (
        SELECT 
            NVL(SUM(ADP_BRUTO), 0), 
            NVL(SUM(ADP_DED), 0), 
            NVL(SUM(APD_NETO), 0)
        FROM ACS_DETALLE_PLANILLA d
        WHERE d.APL_ID = p.APL_ID
    ),
    APL_FECHA_ACTUALIZACION = SYSTIMESTAMP
    WHERE p.APL_ID = v_planilla_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('✅ Planilla generada exitosamente');
    DBMS_OUTPUT.PUT_LINE('   Médicos procesados: ' || v_count_medicos);
    DBMS_OUTPUT.PUT_LINE('   Detalles creados: ' || v_count_detalles);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ ERROR: ' || SQLERRM);
        RAISE_APPLICATION_ERROR(-20002, 'Error al generar planilla de médicos: ' || SQLERRM);
END PRC_GENERAR_PLANILLAS_MEDICOS;
/

SHOW ERRORS;
