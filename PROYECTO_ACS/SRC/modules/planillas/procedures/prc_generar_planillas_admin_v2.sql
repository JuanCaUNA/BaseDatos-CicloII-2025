
CREATE OR REPLACE PROCEDURE PRC_GENERAR_PLANILLAS_ADMIN(
    p_mes  IN NUMBER,
    p_anio IN NUMBER
) AS
    v_planilla_id  NUMBER;
    v_tipo_id      NUMBER;
    v_detalle_id   NUMBER;
    
    v_salario_base NUMBER;
    v_bruto        NUMBER;
    v_deducciones  NUMBER;
    v_neto         NUMBER;
    
    v_monto_movimiento NUMBER;
    
    v_count_admin NUMBER := 0;
    v_count_detalles NUMBER := 0;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Generando planilla de administrativos: ' || p_mes || '/' || p_anio);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    BEGIN
        SELECT ATP_ID INTO v_tipo_id
        FROM ACS_TIPO_PLANILLA
        WHERE UPPER(ATP_APLICA_A) = 'ADMINISTRATIVO' 
          AND ATP_ESTADO = 'ACTIVO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'No existe tipo de planilla para ADMINISTRATIVO');
    END;
    
    INSERT INTO ACS_PLANILLA (
        APL_ANIO, APL_MES, APL_ESTADO, APL_FEC_GEN,
        APL_TOT_BRUTO, APL_TOT_DED, APL_TOT_NETO,
        APL_FECHA_CREACION, APL_FECHA_ACTUALIZACION, ATP_ID
    ) VALUES (
        p_anio, p_mes, 'CONSTRUCCION', SYSTIMESTAMP,
        0, 0, 0, SYSTIMESTAMP, SYSTIMESTAMP, v_tipo_id
    )
    RETURNING APL_ID INTO v_planilla_id;
    
    DBMS_OUTPUT.PUT_LINE('Planilla creada con ID: ' || v_planilla_id);
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR admin IN (
        SELECT 
            p.AUS_ID, 
            pe.APE_NOMBRE, 
            pe.APE_P_APELLIDO, 
            pe.APE_S_APELLIDO,
            800000 AS SALARIO_BASE  -- TODO: Obtener de configuración real
        FROM ACS_PERSONAL_TIPO_PLANILLA p
        JOIN ACS_USUARIO u ON p.AUS_ID = u.AUS_ID
        JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
        WHERE p.ATP_ID = v_tipo_id 
          AND p.APTP_ACTIVO = 1
        ORDER BY pe.APE_P_APELLIDO, pe.APE_NOMBRE
    ) LOOP
        v_count_admin := v_count_admin + 1;
        
        v_salario_base := admin.SALARIO_BASE;
        
        IF v_salario_base IS NULL OR v_salario_base <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('  ⚠ ' || admin.APE_NOMBRE || ' ' || admin.APE_P_APELLIDO || 
                               ' no tiene salario base configurado. Omitiendo...');
            CONTINUE;
        END IF;
        
        v_bruto := v_salario_base;
        
        INSERT INTO ACS_DETALLE_PLANILLA (
            ADP_TIPO_PERSONA, ADP_SALARIO_BASE, ADP_BRUTO, ADP_DED,
            APD_NETO, ADP_EMAIL_ENV, ADP_FECHA_CREACION, ADP_FECHA_ACTUALIZACION,
            APL_ID, AUS_ID
        ) VALUES (
            'ADMINISTRATIVO', v_salario_base, v_bruto, 0,
            v_bruto, 0, SYSTIMESTAMP, SYSTIMESTAMP, v_planilla_id, admin.AUS_ID
        )
        RETURNING ADP_ID INTO v_detalle_id;
        
        v_count_detalles := v_count_detalles + 1;
        
        v_deducciones := 0;
        
        FOR mov IN (
            SELECT ATM_ID, ATM_COD, ATM_NOMBRE, ATM_NATURALEZA
            FROM ACS_TIPO_MOV
            WHERE ATM_ES_AUTOMATICO = 1
              AND ATM_APLICA_A IN ('ADMINISTRATIVO', 'AMBOS')
              AND ATM_ESTADO = 'ACTIVO'
            ORDER BY ATM_PRIORIDAD
        ) LOOP
            v_monto_movimiento := FUN_CALCULAR_MOVIMIENTO(mov.ATM_ID, v_bruto);
            
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
                
                IF mov.ATM_NATURALEZA = 'DEDUCCION' THEN
                    v_deducciones := v_deducciones + v_monto_movimiento;
                ELSIF mov.ATM_NATURALEZA = 'INGRESO' THEN
                    v_bruto := v_bruto + v_monto_movimiento;
                END IF;
            END IF;
        END LOOP;
        
        v_neto := v_bruto - v_deducciones;
        
        UPDATE ACS_DETALLE_PLANILLA
        SET ADP_BRUTO = v_bruto,
            ADP_DED = v_deducciones,
            APD_NETO = v_neto,
            ADP_FECHA_ACTUALIZACION = SYSTIMESTAMP
        WHERE ADP_ID = v_detalle_id;
        
        DBMS_OUTPUT.PUT_LINE('  ✓ ' || admin.APE_NOMBRE || ' ' || admin.APE_P_APELLIDO || 
                           ' - Base: ₡' || ROUND(v_salario_base, 2) ||
                           ' | Bruto: ₡' || ROUND(v_bruto, 2) || 
                           ' | Ded: ₡' || ROUND(v_deducciones, 2) ||
                           ' | Neto: ₡' || ROUND(v_neto, 2));
        
    END LOOP;
    
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
    DBMS_OUTPUT.PUT_LINE('   Administrativos procesados: ' || v_count_admin);
    DBMS_OUTPUT.PUT_LINE('   Detalles creados: ' || v_count_detalles);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ ERROR: ' || SQLERRM);
        RAISE_APPLICATION_ERROR(-20004, 'Error al generar planilla de administrativos: ' || SQLERRM);
END PRC_GENERAR_PLANILLAS_ADMIN;
/

SHOW ERRORS;
