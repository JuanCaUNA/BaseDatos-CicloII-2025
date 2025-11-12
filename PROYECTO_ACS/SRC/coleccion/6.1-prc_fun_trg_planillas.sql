-- ! funciones
-- =============================================================================
-- Función: FUN_CALCULAR_MOVIMIENTO
-- =============================================================================
-- Descripción: Calcula el monto de un movimiento (ingreso/deducción) según:
--   - Modo: FIJO, PORCENTAJE, PERSONALIZADA
--   - Base: BRUTO, SALARIO_BASE, HORAS, PROCEDIMIENTOS
--   - Rangos progresivos (para renta principalmente)
-- =============================================================================
-- Parámetros:
--   p_atm_id:        ID del tipo de movimiento
--   p_base_calculo:  Monto base sobre el cual calcular (bruto, salario, etc)
--   p_apd_id:        ID del detalle de planilla (para trazabilidad)
-- =============================================================================
-- Retorna: Monto calculado (NUMBER)
-- =============================================================================

CREATE OR REPLACE FUNCTION FUN_CALCULAR_MOVIMIENTO(
    p_atm_id       IN NUMBER,
    p_base_calculo IN NUMBER,
    p_apd_id       IN NUMBER DEFAULT NULL
) RETURN NUMBER
IS
    v_modo         VARCHAR2(20);
    v_base         VARCHAR2(20);
    v_porcentaje   NUMBER;
    v_monto_fijo   NUMBER;
    v_resultado    NUMBER := 0;
    v_tiene_rangos NUMBER := 0;
    
    -- Variables para cálculo progresivo
    v_acumulado    NUMBER := 0;
    v_resto        NUMBER := p_base_calculo;
    v_rango_min    NUMBER;
    v_rango_max    NUMBER;
    v_rango_porc   NUMBER;
    v_tramo        NUMBER;
BEGIN
    -- Validar entrada
    IF p_base_calculo IS NULL OR p_base_calculo <= 0 THEN
        RETURN 0;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Calculando movimiento ATM_ID=' || p_atm_id || ' sobre base ' || p_base_calculo || ' (APD_ID=' || NVL(TO_CHAR(p_apd_id), 'NULL') || ')');
    
    -- 1️⃣ Obtener configuración del movimiento
    BEGIN
        SELECT ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO
        INTO v_modo, v_base, v_porcentaje, v_monto_fijo
        FROM ACS_TIPO_MOV
        WHERE ATM_ID = p_atm_id AND ATM_ESTADO = 'ACTIVO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20100, 'Tipo de movimiento no encontrado: ' || p_atm_id);
    END;
    
    -- 2️⃣ Verificar si tiene rangos progresivos
    SELECT COUNT(*)
    INTO v_tiene_rangos
    FROM ACS_TIPO_MOV_RANGO
    WHERE ATM_ID = p_atm_id AND ATMR_ESTADO = 1;
    
    -- 3️⃣ CALCULAR según el modo
    
    -- CASO A: Monto FIJO
    IF v_modo = 'FIJO' THEN
        v_resultado := NVL(v_monto_fijo, 0);
    
    -- CASO B: PORCENTAJE simple (sin rangos)
    ELSIF v_modo = 'PORCENTAJE' AND v_tiene_rangos = 0 THEN
        v_resultado := (p_base_calculo * NVL(v_porcentaje, 0)) / 100;
    
    -- CASO C: PORCENTAJE con RANGOS PROGRESIVOS (Renta)
    ELSIF v_modo = 'PORCENTAJE' AND v_tiene_rangos > 0 THEN
        v_acumulado := 0;
        -- v_resto := p_base_calculo;
        
        -- Iterar por rangos en orden ascendente
        FOR rango IN (
            SELECT ATMR_RANGO_MIN, ATMR_RANGO_MAX, ATMR_PORCENTAJE
            FROM ACS_TIPO_MOV_RANGO
            WHERE ATM_ID = p_atm_id AND ATMR_ESTADO = 1
            ORDER BY ATMR_RANGO_MIN
        ) LOOP
            v_rango_min := rango.ATMR_RANGO_MIN;
            v_rango_max := rango.ATMR_RANGO_MAX;
            v_rango_porc := NVL(rango.ATMR_PORCENTAJE, 0);
            
            -- Si el salario cae en este rango
            IF p_base_calculo > v_rango_min THEN
                -- Calcular cuánto del salario está en este tramo
                IF p_base_calculo <= v_rango_max THEN
                    -- Todo el resto cae en este tramo
                    v_tramo := p_base_calculo - v_rango_min;
                ELSE
                    -- Solo una parte cae en este tramo
                    v_tramo := v_rango_max - v_rango_min;
                END IF;
                
                -- Aplicar porcentaje del tramo
                v_acumulado := v_acumulado + ((v_tramo * v_rango_porc) / 100);
                
                -- Si ya no hay más salario por procesar, salir
                IF p_base_calculo <= v_rango_max THEN
                    EXIT;
                END IF;
            END IF;
        END LOOP;
        
        v_resultado := v_acumulado;
    
    -- CASO D: PERSONALIZADA (para lógicas complejas futuras)
    ELSIF v_modo = 'PERSONALIZADA' THEN
        -- Por ahora, retornar 0 (se calcula fuera de la función)
        v_resultado := 0;
    
    ELSE
        v_resultado := 0;
    END IF;
    
    -- 4️⃣ Redondear a 2 decimales
    v_resultado := ROUND(v_resultado, 2);
    
    RETURN v_resultado;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20101, 'Error en cálculo de movimiento: ' || SQLERRM);
END FUN_CALCULAR_MOVIMIENTO;
/

-- =============================================================================
-- PRUEBAS RÁPIDAS
-- =============================================================================

-- SET SERVEROUTPUT ON;

-- DECLARE
--     v_test_salario NUMBER;
--     v_ccss NUMBER;
--     v_renta NUMBER;
--     v_banco NUMBER;
-- BEGIN
--     DBMS_OUTPUT.PUT_LINE('=================================');
--     DBMS_OUTPUT.PUT_LINE('PRUEBAS FUN_CALCULAR_MOVIMIENTO');
--     DBMS_OUTPUT.PUT_LINE('=================================');
--     DBMS_OUTPUT.PUT_LINE('');
    
--     -- Test 1: Salario bajo (sin renta)
--     v_test_salario := 800000;
--     v_ccss := FUN_CALCULAR_MOVIMIENTO(1, v_test_salario); -- CCSS 9%
--     v_renta := FUN_CALCULAR_MOVIMIENTO(2, v_test_salario); -- Renta progresiva
--     v_banco := FUN_CALCULAR_MOVIMIENTO(4, v_test_salario); -- Banco 1.5%
    
--     DBMS_OUTPUT.PUT_LINE('📊 Salario: ₡' || TO_CHAR(v_test_salario, '999G999G999'));
--     DBMS_OUTPUT.PUT_LINE('   CCSS (9%): ₡' || TO_CHAR(v_ccss, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Renta: ₡' || TO_CHAR(v_renta, '999G999G999.00') || ' (exento)');
--     DBMS_OUTPUT.PUT_LINE('   Banco (1.5%): ₡' || TO_CHAR(v_banco, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Total deducciones: ₡' || TO_CHAR(v_ccss + v_renta + v_banco, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Neto: ₡' || TO_CHAR(v_test_salario - (v_ccss + v_renta + v_banco), '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('');
    
--     -- Test 2: Salario medio (con renta 10%)
--     v_test_salario := 1200000;
--     v_ccss := FUN_CALCULAR_MOVIMIENTO(1, v_test_salario);
--     v_renta := FUN_CALCULAR_MOVIMIENTO(2, v_test_salario);
--     v_banco := FUN_CALCULAR_MOVIMIENTO(4, v_test_salario);
    
--     DBMS_OUTPUT.PUT_LINE('📊 Salario: ₡' || TO_CHAR(v_test_salario, '999G999G999'));
--     DBMS_OUTPUT.PUT_LINE('   CCSS (9%): ₡' || TO_CHAR(v_ccss, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Renta progresiva: ₡' || TO_CHAR(v_renta, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Banco (1.5%): ₡' || TO_CHAR(v_banco, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Total deducciones: ₡' || TO_CHAR(v_ccss + v_renta + v_banco, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Neto: ₡' || TO_CHAR(v_test_salario - (v_ccss + v_renta + v_banco), '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('');
    
--     -- Test 3: Salario alto (múltiples rangos)
--     v_test_salario := 3000000;
--     v_ccss := FUN_CALCULAR_MOVIMIENTO(1, v_test_salario);
--     v_renta := FUN_CALCULAR_MOVIMIENTO(2, v_test_salario);
--     v_banco := FUN_CALCULAR_MOVIMIENTO(4, v_test_salario);
    
--     DBMS_OUTPUT.PUT_LINE('📊 Salario: ₡' || TO_CHAR(v_test_salario, '999G999G999'));
--     DBMS_OUTPUT.PUT_LINE('   CCSS (9%): ₡' || TO_CHAR(v_ccss, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Renta progresiva: ₡' || TO_CHAR(v_renta, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Banco (1.5%): ₡' || TO_CHAR(v_banco, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Total deducciones: ₡' || TO_CHAR(v_ccss + v_renta + v_banco, '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('   Neto: ₡' || TO_CHAR(v_test_salario - (v_ccss + v_renta + v_banco), '999G999G999.00'));
--     DBMS_OUTPUT.PUT_LINE('');
    
--     DBMS_OUTPUT.PUT_LINE('=================================');
--     DBMS_OUTPUT.PUT_LINE('✅ Función compilada y probada');
--     DBMS_OUTPUT.PUT_LINE('=================================');
-- END;
-- /


-- ! procedimientos

CREATE OR REPLACE PROCEDURE PRC_Aplicar_Planilla(
    p_planilla_id IN NUMBER
) AS
    v_existe NUMBER;
BEGIN
    -- 1️⃣ Verificar existencia de la planilla
    SELECT COUNT(*) INTO v_existe
    FROM ACS_PLANILLA
    WHERE APL_ID = p_planilla_id;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'No existe la planilla especificada.');
    END IF;

    -- 2️⃣ Marcar todos los detalles como PROCESADOS
    UPDATE ACS_DETALLE_PLANILLA
    SET ADP_EMAIL_ENV = 1
    WHERE APL_ID = p_planilla_id;

    -- 3️⃣ Cambiar el estado de la planilla
    UPDATE ACS_PLANILLA
    SET APL_ESTADO = 'PROCESADA',
        APL_FEC_PRO = SYSTIMESTAMP,
        APL_FECHA_ACTUALIZACION = SYSTIMESTAMP
    WHERE APL_ID = p_planilla_id;

    -- 4️⃣ (Opcional) disparar movimientos automáticos
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Planilla ' || p_planilla_id || ' procesada correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20011, 'Error al procesar la planilla: ' || SQLERRM);
END;
/

-- =============================================
-- Procedimiento: PRC_Enviar_Comprobantes
-- Genera y envía comprobantes de pago por correo, marca detalles como notificados
-- Cumple con el enunciado y estructura de tablas unificada del sistema ACS
-- Actualizado: 2025-11-09 - Uso de ACS_PLANILLA y ACS_DETALLE_PLANILLA
-- =============================================
CREATE OR REPLACE PROCEDURE PRC_Enviar_Comprobantes(
p_planilla_id IN NUMBER
) AS
v_comprobante_html CLOB;
v_email VARCHAR2(255);
v_nombre_completo VARCHAR2(400);
v_count NUMBER := 0;
v_existe NUMBER;
BEGIN
-- Validar que la planilla exista y esté en estado adecuado
SELECT COUNT(*) INTO v_existe
FROM ACS_PLANILLA 
WHERE APL_ID = p_planilla_id 
    AND APL_ESTADO IN ('APROBADA', 'PROCESADA');

IF v_existe = 0 THEN
    RAISE_APPLICATION_ERROR(-20050, 'Planilla no existe o no está aprobada/procesada.');
END IF;

-- Recorrer cada detalle de planilla para enviar comprobante
FOR r_detalle IN (
    SELECT 
    dp.ADP_ID,
    dp.ADP_COMPROBANTE_HTML,
    dp.ADP_BRUTO,
    dp.ADP_DED,
    dp.APD_NETO,
    dp.AUS_ID,
    pe.APE_EMAIL,
    pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO || ' ' || COALESCE(pe.APE_S_APELLIDO, '') AS nombre_completo
    FROM ACS_DETALLE_PLANILLA dp
    JOIN ACS_USUARIO u ON dp.AUS_ID = u.AUS_ID
    JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
    WHERE dp.APL_ID = p_planilla_id
    AND dp.ADP_EMAIL_ENV = 0  -- Solo enviar los que NO han sido enviados
) LOOP
    v_email := r_detalle.APE_EMAIL;
    v_nombre_completo := r_detalle.nombre_completo;
    
    -- Generar comprobante HTML si no existe
    IF r_detalle.ADP_COMPROBANTE_HTML IS NULL THEN
    v_comprobante_html := 
        '<html><body>' ||
        '<h2>Comprobante de Pago - Sistema ACS</h2>' ||
        '<p><strong>Empleado:</strong> ' || v_nombre_completo || '</p>' ||
        '<p><strong>Bruto:</strong> ₡' || TO_CHAR(r_detalle.ADP_BRUTO, '999,999,999.99') || '</p>' ||
        '<p><strong>Deducciones:</strong> ₡' || TO_CHAR(r_detalle.ADP_DED, '999,999,999.99') || '</p>' ||
        '<p><strong>Neto a Pagar:</strong> ₡' || TO_CHAR(r_detalle.APD_NETO, '999,999,999.99') || '</p>' ||
        '<p>Este es un documento generado automáticamente.</p>' ||
        '</body></html>';
    
    -- Actualizar comprobante en BD
    UPDATE ACS_DETALLE_PLANILLA
    SET ADP_COMPROBANTE_HTML = v_comprobante_html
    WHERE ADP_ID = r_detalle.ADP_ID;
    ELSE
    v_comprobante_html := r_detalle.ADP_COMPROBANTE_HTML;
    END IF;

    -- Enviar correo (comentado hasta que exista el procedimiento de correo)
    BEGIN
    ACS_PRC_CORREO_NOTIFICADOR(
        p_destinatario => 'frankodbz@gmail.com',
        p_asunto => 'Comprobante de Pago - Planilla ' || p_planilla_id,
        p_mensaje => v_comprobante_html
    );
    
    -- Por ahora solo marcamos como notificado (simula envío exitoso)
    UPDATE ACS_DETALLE_PLANILLA
    SET ADP_EMAIL_ENV = 1,
        ADP_FECHA_NOTIFICACION = SYSTIMESTAMP
    WHERE ADP_ID = r_detalle.ADP_ID;
    
    v_count := v_count + 1;
    
    EXCEPTION
    WHEN OTHERS THEN
        -- Registrar error pero continuar con otros
        DECLARE
        v_error_msg VARCHAR2(30) := SUBSTR(SQLERRM, 1, 30);
        BEGIN
        INSERT INTO ACS_ENVIO_COMP (AEC_EMAIL, AEC_FECHA_ENVIO, AEC_ERROR, ADP_ID)
        VALUES (v_email, CAST(SYSDATE AS TIMESTAMP), v_error_msg, r_detalle.ADP_ID);
        END;
    END;
END LOOP;

-- Actualizar estado de la planilla si todos fueron notificados
DECLARE
    v_pendientes NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_pendientes
    FROM ACS_DETALLE_PLANILLA
    WHERE APL_ID = p_planilla_id AND ADP_EMAIL_ENV = 0;
    
    IF v_count > 0 AND v_pendientes = 0 THEN
    UPDATE ACS_PLANILLA
    SET APL_ESTADO = 'NOTIFICADA',
        APL_FEC_NOT = SYSTIMESTAMP,
        APL_FECHA_ACTUALIZACION = SYSTIMESTAMP
    WHERE APL_ID = p_planilla_id;
    END IF;
END;

COMMIT;
DBMS_OUTPUT.PUT_LINE('✅ Se enviaron ' || v_count || ' comprobantes correctamente.');

EXCEPTION
WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20051, 'Error al enviar comprobantes: ' || SQLERRM);
END PRC_Enviar_Comprobantes;
/

-- =============================================================================
-- Procedimiento: PRC_GENERAR_PLANILLAS_ADMIN (Versión 2 - COMPLETA)
-- =============================================================================
-- Descripción: Genera planillas mensuales para personal administrativo con:
--   1. Uso de salario base del usuario (ACS_USUARIO)
--   2. Aplicación automática de movimientos con rangos progresivos
--   3. Registro detallado en ACS_MOVIMIENTO_PLANILLA
-- =============================================================================
-- Parámetros:
--   p_mes:  Mes de la planilla (1-12)
--   p_anio: Año de la planilla
-- =============================================================================

CREATE OR REPLACE PROCEDURE PRC_GENERAR_PLANILLAS_ADMIN(
    p_mes  IN NUMBER,
    p_anio IN NUMBER
) AS
    v_planilla_id  NUMBER;
    v_tipo_id      NUMBER;
    v_detalle_id   NUMBER;
    
    -- Totales del administrativo
    v_salario_base NUMBER;
    v_bruto        NUMBER;
    v_deducciones  NUMBER;
    v_neto         NUMBER;
    
    -- Para movimientos automáticos
    v_monto_movimiento NUMBER;
    
    -- Contadores
    v_count_admin NUMBER := 0;
    v_count_detalles NUMBER := 0;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Generando planilla de administrativos: ' || p_mes || '/' || p_anio);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- 1️⃣ Obtener tipo de planilla de administrativos
    BEGIN
        SELECT ATP_ID INTO v_tipo_id
        FROM ACS_TIPO_PLANILLA
        WHERE UPPER(ATP_APLICA_A) = 'ADMINISTRATIVO' 
        AND ATP_ESTADO = 'ACTIVO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'No existe tipo de planilla para ADMINISTRATIVO');
    END;
    
    -- 2️⃣ Crear encabezado de planilla
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
    
    -- 3️⃣ Procesar cada administrativo asignado al tipo de planilla
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
        
        -- A) Obtener salario base del usuario
        v_salario_base := admin.SALARIO_BASE;
        
        -- Validar que tenga salario configurado
        IF v_salario_base IS NULL OR v_salario_base <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('  ⚠ ' || admin.APE_NOMBRE || ' ' || admin.APE_P_APELLIDO || 
                            ' no tiene salario base configurado. Omitiendo...');
            CONTINUE;
        END IF;
        
        -- B) El bruto inicial es el salario base
        v_bruto := v_salario_base;
        
        -- C) Crear detalle de planilla
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
        
        -- D) Aplicar MOVIMIENTOS AUTOMÁTICOS (deducciones e ingresos)
        v_deducciones := 0;
        
        FOR mov IN (
            SELECT ATM_ID, ATM_COD, ATM_NOMBRE, ATM_NATURALEZA
            FROM ACS_TIPO_MOV
            WHERE ATM_ES_AUTOMATICO = 1
            AND ATM_APLICA_A IN ('ADMINISTRATIVO', 'AMBOS')
            AND ATM_ESTADO = 'ACTIVO'
            ORDER BY ATM_PRIORIDAD
        ) LOOP
            -- Calcular monto del movimiento (maneja rangos automáticamente)
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
                
                -- Acumular según naturaleza
                IF mov.ATM_NATURALEZA = 'DEDUCCION' THEN
                    v_deducciones := v_deducciones + v_monto_movimiento;
                ELSIF mov.ATM_NATURALEZA = 'INGRESO' THEN
                    v_bruto := v_bruto + v_monto_movimiento;
                END IF;
            END IF;
        END LOOP;
        
        -- E) Calcular NETO y actualizar detalle
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

-- SHOW ERRORS;

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
    v_turnos       NUMBER;
    v_procedimientos NUMBER;
    v_bruto        NUMBER;
    v_deducciones  NUMBER;
    v_neto         NUMBER;
    v_monto_movimiento NUMBER;
    v_count_medicos NUMBER := 0;
    v_count_detalles NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Generando planilla de médicos: ' || p_mes || '/' || p_anio);
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    BEGIN
        SELECT ATP_ID INTO v_tipo_id
        FROM ACS_TIPO_PLANILLA
        WHERE UPPER(ATP_APLICA_A) = 'MEDICO' AND ATP_ESTADO = 'ACTIVO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'No existe tipo de planilla para MEDICO');
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
    
    -- ✓ CORREGIDO: Agregar JOIN con ACS_MEDICO para obtener AME_ID
    FOR medico IN (
        SELECT p.AUS_ID, pe.APE_NOMBRE, pe.APE_P_APELLIDO, pe.APE_S_APELLIDO, m.AME_ID
        FROM ACS_PERSONAL_TIPO_PLANILLA p
        JOIN ACS_USUARIO u ON p.AUS_ID = u.AUS_ID
        JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
        JOIN ACS_MEDICO m ON m.AUS_ID = u.AUS_ID
        WHERE p.ATP_ID = v_tipo_id AND p.APTP_ACTIVO = 1
        ORDER BY pe.APE_P_APELLIDO, pe.APE_NOMBRE
    ) LOOP
        v_count_medicos := v_count_medicos + 1;
        v_turnos := 0;
        
        FOR turno IN (
            SELECT 
                dm.ADM_ID, t.ATU_TIPO_PAGO, t.ATU_PAGO,
                CASE 
                    WHEN t.ATU_TIPO_PAGO = 'HORAS' THEN
                        ROUND((CAST(dm.ADM_HR_FIN AS DATE) - CAST(dm.ADM_HR_INICIO AS DATE)) * 24, 2) * t.ATU_PAGO
                    WHEN t.ATU_TIPO_PAGO = 'TURNO' THEN t.ATU_PAGO
                    ELSE 0
                END AS PAGO_CALCULADO
            FROM ACS_DETALLE_MENSUAL dm
            JOIN ACS_TURNO t ON dm.ATU_ID = t.ATU_ID
            JOIN ACS_ESCALA_MENSUAL em ON dm.AEM_ID = em.AEM_ID
            WHERE em.AEM_MES = p_mes AND em.AEM_ANIO = p_anio
            AND dm.AME_ID = medico.AME_ID  -- ✓ CORREGIDO: Buscar por AME_ID
            AND dm.ADM_ESTADO_TURNO = 'CUMPLIDO'
        ) LOOP
            v_turnos := v_turnos + turno.PAGO_CALCULADO;
        END LOOP;
        
        v_procedimientos := 0;
        BEGIN
            SELECT NVL(SUM(pa.APA_PAGO), 0)
            INTO v_procedimientos
            FROM ACS_PROC_APLICADO pa
            JOIN ACS_DETALLE_MENSUAL dm ON pa.AME_ID = dm.AME_ID
            JOIN ACS_ESCALA_MENSUAL em ON dm.AEM_ID = em.AEM_ID
            WHERE em.AEM_MES = p_mes AND em.AEM_ANIO = p_anio
            AND dm.AME_ID = medico.AME_ID;  -- ✓ CORREGIDO
        EXCEPTION
            WHEN NO_DATA_FOUND THEN v_procedimientos := 0;
        END;
        
        v_bruto := v_turnos + v_procedimientos;
        
        IF v_bruto <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('  ⚠ ' || medico.APE_NOMBRE || ' ' || medico.APE_P_APELLIDO || ' no tiene turnos este mes.');
            CONTINUE;
        END IF;
        
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
        v_deducciones := 0;
        
        FOR mov IN (
            SELECT ATM_ID, ATM_COD, ATM_NOMBRE, ATM_NATURALEZA
            FROM ACS_TIPO_MOV
            WHERE ATM_ES_AUTOMATICO = 1
            AND ATM_APLICA_A IN ('MEDICO', 'AMBOS')
            AND ATM_ESTADO = 'ACTIVO'
            ORDER BY ATM_PRIORIDAD
        ) LOOP
            v_monto_movimiento := FUN_CALCULAR_MOVIMIENTO(mov.ATM_ID, v_bruto);
            
            IF v_monto_movimiento > 0 THEN
                IF mov.ATM_NATURALEZA = 'DEDUCCION' THEN
                    v_deducciones := v_deducciones + v_monto_movimiento;
                END IF;
            END IF;
        END LOOP;
        
        v_neto := v_bruto - v_deducciones;
        
        UPDATE ACS_DETALLE_PLANILLA
        SET ADP_DED = v_deducciones,
            APD_NETO = v_neto,
            ADP_FECHA_ACTUALIZACION = SYSTIMESTAMP
        WHERE ADP_ID = v_detalle_id;
        
        DBMS_OUTPUT.PUT_LINE('✓ ' || medico.APE_NOMBRE || ' ' || medico.APE_P_APELLIDO || 
                           ' - Base: ₡' || v_bruto || ' | Bruto: ₡' || v_bruto || 
                           ' | Ded: ₡' || v_deducciones || ' | Neto: ₡' || v_neto);
    END LOOP;
    
    UPDATE ACS_PLANILLA
    SET APL_TOT_BRUTO = (SELECT NVL(SUM(ADP_BRUTO), 0) FROM ACS_DETALLE_PLANILLA WHERE APL_ID = v_planilla_id),
        APL_TOT_DED = (SELECT NVL(SUM(ADP_DED), 0) FROM ACS_DETALLE_PLANILLA WHERE APL_ID = v_planilla_id),
        APL_TOT_NETO = (SELECT NVL(SUM(APD_NETO), 0) FROM ACS_DETALLE_PLANILLA WHERE APL_ID = v_planilla_id),
        APL_FECHA_ACTUALIZACION = SYSTIMESTAMP
    WHERE APL_ID = v_planilla_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('✓ Planilla generada exitosamente');
    DBMS_OUTPUT.PUT_LINE('Médicos procesados: ' || v_count_medicos);
    DBMS_OUTPUT.PUT_LINE('Detalles creados: ' || v_count_detalles);
    DBMS_OUTPUT.PUT_LINE('========================================');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM);
        RAISE;
END PRC_GENERAR_PLANILLAS_MEDICOS;
/

SHOW ERRORS;

-- SHOW ERRORS;

CREATE OR REPLACE PROCEDURE PRC_Marcar_Detalle_Notificado(
p_detalle_id IN NUMBER
) AS
    V_EXISTENTES NUMBER;
BEGIN
    -- Verificar existencia
    SELECT COUNT(*) INTO V_EXISTENTES
    FROM ACS_DETALLE_PLANILLA
    WHERE ADP_ID = p_detalle_id;
    IF V_EXISTENTES = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'No existe el detalle de planilla especificado.');
    END IF;


    -- Marcar como notificado
    UPDATE ACS_DETALLE_PLANILLA
    SET ADP_EMAIL_ENV = 1,
        ADP_FECHA_NOTIFICACION = SYSTIMESTAMP,
        ADP_FECHA_ACTUALIZACION = SYSTIMESTAMP
    WHERE ADP_ID = p_detalle_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('📨 Detalle ' || p_detalle_id || ' marcado como notificado.');
    EXCEPTION
WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20021, 'Error al marcar detalle como notificado: ' || SQLERRM);
END;
/

-- ! Triggers

CREATE OR REPLACE TRIGGER TRG_VALIDA_USUARIO_PLANILLA
BEFORE INSERT OR UPDATE ON ACS_DETALLE_PLANILLA
FOR EACH ROW
DECLARE
    V_APLICA_A VARCHAR2(20);
    V_ES_MEDICO NUMBER;
    V_ES_ADMIN  NUMBER;
BEGIN
    SELECT TP.ATP_APLICA_A
        INTO V_APLICA_A
        FROM ACS_PLANILLA P
        JOIN ACS_TIPO_PLANILLA TP ON TP.ATP_ID = P.ATP_ID
    WHERE P.APL_ID = :NEW.APL_ID;

    SELECT COUNT(*) INTO V_ES_MEDICO FROM ACS_MEDICO         WHERE AUS_ID = :NEW.AUS_ID;
    SELECT COUNT(*) INTO V_ES_ADMIN  FROM ACS_ADMINISTRATIVO WHERE AUS_ID = :NEW.AUS_ID;

    IF V_APLICA_A = 'MEDICO' THEN
        IF V_ES_MEDICO = 0 THEN
        RAISE_APPLICATION_ERROR(-20001,'EL USUARIO NO ESTÁ REGISTRADO COMO MÉDICO PARA ESTA PLANILLA');
        END IF;
        :NEW.ADP_TIPO_PERSONA := 'MEDICO';
    ELSIF V_APLICA_A = 'ADMINISTRATIVO' THEN
        IF V_ES_ADMIN = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,'EL USUARIO NO ESTÁ REGISTRADO COMO ADMINISTRATIVO PARA ESTA PLANILLA');
        END IF;
        :NEW.ADP_TIPO_PERSONA := 'ADMINISTRATIVO';
    ELSE
        IF (V_ES_MEDICO + V_ES_ADMIN) = 0 THEN
        RAISE_APPLICATION_ERROR(-20003,'EL USUARIO NO ESTÁ REGISTRADO NI COMO MÉDICO NI COMO ADMINISTRATIVO');
        END IF;
        IF :NEW.ADP_TIPO_PERSONA IS NULL THEN
        :NEW.ADP_TIPO_PERSONA := CASE WHEN V_ES_MEDICO=1 THEN 'MEDICO' ELSE 'ADMINISTRATIVO' END;
        END IF;
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_VALIDA_MOVIMIENTO_APLICA_A
BEFORE INSERT OR UPDATE ON ACS_MOVIMIENTO_PLANILLA
FOR EACH ROW
DECLARE
    V_TIPO_PERSONA  VARCHAR2(20);
    V_APLICA_A_MOV  VARCHAR2(20);
BEGIN
    SELECT ADP_TIPO_PERSONA INTO V_TIPO_PERSONA
    FROM ACS_DETALLE_PLANILLA
    WHERE ADP_ID = :NEW.APD_ID;

    SELECT ATM_APLICA_A INTO V_APLICA_A_MOV
    FROM ACS_TIPO_MOV
    WHERE ATM_ID = :NEW.ATM_ID;

    IF V_APLICA_A_MOV <> 'AMBOS' AND V_APLICA_A_MOV <> V_TIPO_PERSONA THEN
        RAISE_APPLICATION_ERROR(-20004,'EL MOVIMIENTO NO APLICA AL TIPO DE PERSONA DEL DETALLE');
    END IF;
END;
/



CREATE OR REPLACE TRIGGER TRG_TURNO_PLANILLA_BI
BEFORE INSERT ON ACS_TURNO_PLANILLA
FOR EACH ROW
BEGIN
    :NEW.ATRP_PROCESADO := 1;
    :NEW.ATRP_FECHA_PROCESAMIENTO := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER TRG_PROC_PLANILLA_BI
BEFORE INSERT ON ACS_PROCEDIMIENTO_PLANILLA
FOR EACH ROW
BEGIN
    :NEW.APRP_PROCESADO := 1;
    :NEW.APRP_FECHA_PROCESAMIENTO := SYSTIMESTAMP;
END;
/


CREATE OR REPLACE TRIGGER TRG_ENVIO_COMPROBANTE_AI
AFTER INSERT ON ACS_ENVIO_COMP
FOR EACH ROW
BEGIN
    UPDATE ACS_DETALLE_PLANILLA
    SET ADP_EMAIL_ENV = 1,
        ADP_FECHA_NOTIFICACION = :NEW.AEC_FECHA_ENVIO
    WHERE ADP_ID = :NEW.ADP_ID;
END;
/



CREATE OR REPLACE TRIGGER TRG_MP_RECALC_MOV
FOR INSERT OR UPDATE OR DELETE ON ACS_MOVIMIENTO_PLANILLA
COMPOUND TRIGGER
TYPE T_IDS IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
G_ADP_IDS T_IDS;

PROCEDURE ADD_ADP(P_ADP NUMBER) IS
BEGIN
    IF P_ADP IS NOT NULL THEN
    G_ADP_IDS(G_ADP_IDS.COUNT+1) := P_ADP;
    END IF;
END;

AFTER EACH ROW IS
BEGIN
    ADD_ADP(NVL(:NEW.APD_ID,:OLD.APD_ID));
END AFTER EACH ROW;

AFTER STATEMENT IS
    V_SALARIO   NUMBER;
    V_INGRESOS  NUMBER;
    V_DEDUCS    NUMBER;
    V_TURNOS    NUMBER;
    V_PROCS     NUMBER;
    V_BRUTO     NUMBER;
    V_NETO      NUMBER;
    V_APL_ID    NUMBER;
BEGIN
    FOR I IN 1..G_ADP_IDS.COUNT LOOP
    SELECT NVL(ADP_SALARIO_BASE,0), APL_ID
        INTO V_SALARIO, V_APL_ID
        FROM ACS_DETALLE_PLANILLA
    WHERE ADP_ID = G_ADP_IDS(I);

    SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='INGRESO'   THEN MP.AMP_MONTO ELSE 0 END),0),
            NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='DEDUCCION' THEN MP.AMP_MONTO ELSE 0 END),0)
        INTO V_INGRESOS, V_DEDUCS
        FROM ACS_MOVIMIENTO_PLANILLA MP
        JOIN ACS_TIPO_MOV TM ON TM.ATM_ID = MP.ATM_ID
    WHERE MP.APD_ID = G_ADP_IDS(I);

    SELECT NVL(SUM(ATRP_MONTO_PAGADO_MEDICO),0)
        INTO V_TURNOS
        FROM ACS_TURNO_PLANILLA
    WHERE ADP_ID = G_ADP_IDS(I);

    SELECT NVL(SUM(APRP_MONTO_PAGADO_MEDICO),0)
        INTO V_PROCS
        FROM ACS_PROCEDIMIENTO_PLANILLA
    WHERE ADP_ID = G_ADP_IDS(I);

    V_BRUTO := V_SALARIO + V_INGRESOS + V_TURNOS + V_PROCS;
    V_NETO  := V_BRUTO - V_DEDUCS;

    UPDATE ACS_DETALLE_PLANILLA
        SET ADP_BRUTO = V_BRUTO,
            ADP_DED = V_DEDUCS,
            APD_NETO = V_NETO
    WHERE ADP_ID = G_ADP_IDS(I);

    UPDATE ACS_PLANILLA P
        SET APL_TOT_BRUTO = (SELECT NVL(SUM(ADP_BRUTO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID),
            APL_TOT_DED = (SELECT NVL(SUM(ADP_DED),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID),
            APL_TOT_NETO = (SELECT NVL(SUM(APD_NETO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID)
    WHERE P.APL_ID = V_APL_ID;
    END LOOP;
    G_ADP_IDS.DELETE;
END AFTER STATEMENT;
END;
/


CREATE OR REPLACE TRIGGER TRG_TURNO_RECALC
FOR INSERT OR UPDATE OR DELETE ON ACS_TURNO_PLANILLA
COMPOUND TRIGGER
TYPE T_IDS IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
G_ADP_IDS T_IDS;

PROCEDURE ADD_ADP(P_ADP NUMBER) IS
BEGIN
    IF P_ADP IS NOT NULL THEN
    G_ADP_IDS(G_ADP_IDS.COUNT+1) := P_ADP;
    END IF;
END;

AFTER EACH ROW IS
BEGIN
    ADD_ADP(NVL(:NEW.ADP_ID,:OLD.ADP_ID));
END AFTER EACH ROW;

AFTER STATEMENT IS
    V_APL_ID NUMBER;
BEGIN
    FOR I IN 1..G_ADP_IDS.COUNT LOOP
    UPDATE ACS_DETALLE_PLANILLA D
        SET ADP_BRUTO = NVL(ADP_SALARIO_BASE,0)
                + (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='INGRESO' THEN MP.AMP_MONTO ELSE 0 END),0)
                        FROM ACS_MOVIMIENTO_PLANILLA MP
                        JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID
                    WHERE MP.APD_ID=D.ADP_ID)
                + (SELECT NVL(SUM(ATRP_MONTO_PAGADO_MEDICO),0) FROM ACS_TURNO_PLANILLA T WHERE T.ADP_ID=D.ADP_ID)
                + (SELECT NVL(SUM(APRP_MONTO_PAGADO_MEDICO),0) FROM ACS_PROCEDIMIENTO_PLANILLA P WHERE P.ADP_ID=D.ADP_ID),
            ADP_DED = (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='DEDUCCION' THEN MP.AMP_MONTO ELSE 0 END),0)
                            FROM ACS_MOVIMIENTO_PLANILLA MP
                            JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID
                            WHERE MP.APD_ID=D.ADP_ID),
            APD_NETO = (NVL(ADP_SALARIO_BASE,0)
                + (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='INGRESO' THEN MP.AMP_MONTO ELSE 0 END),0) FROM ACS_MOVIMIENTO_PLANILLA MP JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID WHERE MP.APD_ID=D.ADP_ID)
                + (SELECT NVL(SUM(ATRP_MONTO_PAGADO_MEDICO),0) FROM ACS_TURNO_PLANILLA T WHERE T.ADP_ID=D.ADP_ID)
                + (SELECT NVL(SUM(APRP_MONTO_PAGADO_MEDICO),0) FROM ACS_PROCEDIMIENTO_PLANILLA P WHERE P.ADP_ID=D.ADP_ID))
                - (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='DEDUCCION' THEN MP.AMP_MONTO ELSE 0 END),0) FROM ACS_MOVIMIENTO_PLANILLA MP JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID WHERE MP.APD_ID=D.ADP_ID)
    WHERE D.ADP_ID = G_ADP_IDS(I);

    SELECT APL_ID INTO V_APL_ID FROM ACS_DETALLE_PLANILLA WHERE ADP_ID = G_ADP_IDS(I);

    UPDATE ACS_PLANILLA P
        SET APL_TOT_BRUTO = (SELECT NVL(SUM(ADP_BRUTO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID),
            APL_TOT_DED = (SELECT NVL(SUM(ADP_DED),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID),
            APL_TOT_NETO = (SELECT NVL(SUM(APD_NETO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID)
    WHERE P.APL_ID = V_APL_ID;
    END LOOP;
    G_ADP_IDS.DELETE;
END AFTER STATEMENT;
END;
/


CREATE OR REPLACE TRIGGER TRG_PROC_RECALC
FOR INSERT OR UPDATE OR DELETE ON ACS_PROCEDIMIENTO_PLANILLA
COMPOUND TRIGGER
TYPE T_IDS IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
G_ADP_IDS T_IDS;

PROCEDURE ADD_ADP(P_ADP NUMBER) IS
BEGIN
    IF P_ADP IS NOT NULL THEN
    G_ADP_IDS(G_ADP_IDS.COUNT+1) := P_ADP;
    END IF;
END;

AFTER EACH ROW IS
BEGIN
    ADD_ADP(NVL(:NEW.ADP_ID,:OLD.ADP_ID));
END AFTER EACH ROW;

AFTER STATEMENT IS
    V_APL_ID NUMBER;
BEGIN
    FOR I IN 1..G_ADP_IDS.COUNT LOOP
    UPDATE ACS_DETALLE_PLANILLA D
        SET ADP_BRUTO = NVL(ADP_SALARIO_BASE,0)
                + (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='INGRESO' THEN MP.AMP_MONTO ELSE 0 END),0)
                        FROM ACS_MOVIMIENTO_PLANILLA MP
                        JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID
                    WHERE MP.APD_ID=D.ADP_ID)
                + (SELECT NVL(SUM(ATRP_MONTO_PAGADO_MEDICO),0) FROM ACS_TURNO_PLANILLA T WHERE T.ADP_ID=D.ADP_ID)
                + (SELECT NVL(SUM(APRP_MONTO_PAGADO_MEDICO),0) FROM ACS_PROCEDIMIENTO_PLANILLA P WHERE P.ADP_ID=D.ADP_ID),
            ADP_DED = (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='DEDUCCION' THEN MP.AMP_MONTO ELSE 0 END),0)
                            FROM ACS_MOVIMIENTO_PLANILLA MP
                            JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID
                            WHERE MP.APD_ID=D.ADP_ID),
            APD_NETO = (NVL(ADP_SALARIO_BASE,0)
                + (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='INGRESO' THEN MP.AMP_MONTO ELSE 0 END),0) FROM ACS_MOVIMIENTO_PLANILLA MP JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID WHERE MP.APD_ID=D.ADP_ID)
                + (SELECT NVL(SUM(ATRP_MONTO_PAGADO_MEDICO),0) FROM ACS_TURNO_PLANILLA T WHERE T.ADP_ID=D.ADP_ID)
                + (SELECT NVL(SUM(APRP_MONTO_PAGADO_MEDICO),0) FROM ACS_PROCEDIMIENTO_PLANILLA P WHERE P.ADP_ID=D.ADP_ID))
                - (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='DEDUCCION' THEN MP.AMP_MONTO ELSE 0 END),0) FROM ACS_MOVIMIENTO_PLANILLA MP JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID WHERE MP.APD_ID=D.ADP_ID)
    WHERE D.ADP_ID = G_ADP_IDS(I);

    SELECT APL_ID INTO V_APL_ID FROM ACS_DETALLE_PLANILLA WHERE ADP_ID = G_ADP_IDS(I);

    UPDATE ACS_PLANILLA P
        SET APL_TOT_BRUTO = (SELECT NVL(SUM(ADP_BRUTO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID),
            APL_TOT_DED = (SELECT NVL(SUM(ADP_DED),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID),
            APL_TOT_NETO = (SELECT NVL(SUM(APD_NETO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = V_APL_ID)
    WHERE P.APL_ID = V_APL_ID;
    END LOOP;
    G_ADP_IDS.DELETE;
END AFTER STATEMENT;
END;
/

CREATE OR REPLACE TRIGGER TRG_DETALLE_SALARIO_AI
AFTER UPDATE OF ADP_SALARIO_BASE ON ACS_DETALLE_PLANILLA
FOR EACH ROW
BEGIN
UPDATE ACS_DETALLE_PLANILLA D
    SET ADP_BRUTO = NVL(:NEW.ADP_SALARIO_BASE,0)
            + (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='INGRESO' THEN MP.AMP_MONTO ELSE 0 END),0)
                    FROM ACS_MOVIMIENTO_PLANILLA MP
                    JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID
                WHERE MP.APD_ID=D.ADP_ID)
            + (SELECT NVL(SUM(ATRP_MONTO_PAGADO_MEDICO),0) FROM ACS_TURNO_PLANILLA T WHERE T.ADP_ID=D.ADP_ID)
            + (SELECT NVL(SUM(APRP_MONTO_PAGADO_MEDICO),0) FROM ACS_PROCEDIMIENTO_PLANILLA P WHERE P.ADP_ID=D.ADP_ID),
        ADP_DED = (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='DEDUCCION' THEN MP.AMP_MONTO ELSE 0 END),0)
                        FROM ACS_MOVIMIENTO_PLANILLA MP
                        JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID
                        WHERE MP.APD_ID=D.ADP_ID),
        APD_NETO = (NVL(:NEW.ADP_SALARIO_BASE,0)
            + (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='INGRESO' THEN MP.AMP_MONTO ELSE 0 END),0) FROM ACS_MOVIMIENTO_PLANILLA MP JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID WHERE MP.APD_ID=D.ADP_ID)
            + (SELECT NVL(SUM(ATRP_MONTO_PAGADO_MEDICO),0) FROM ACS_TURNO_PLANILLA T WHERE T.ADP_ID=D.ADP_ID)
            + (SELECT NVL(SUM(APRP_MONTO_PAGADO_MEDICO),0) FROM ACS_PROCEDIMIENTO_PLANILLA P WHERE P.ADP_ID=D.ADP_ID))
            - (SELECT NVL(SUM(CASE WHEN TM.ATM_NATURALEZA='DEDUCCION' THEN MP.AMP_MONTO ELSE 0 END),0) FROM ACS_MOVIMIENTO_PLANILLA MP JOIN ACS_TIPO_MOV TM ON TM.ATM_ID=MP.ATM_ID WHERE MP.APD_ID=D.ADP_ID)
WHERE D.ADP_ID = :NEW.ADP_ID;

UPDATE ACS_PLANILLA P
    SET APL_TOT_BRUTO = (SELECT NVL(SUM(ADP_BRUTO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = :NEW.APL_ID),
        APL_TOT_DED = (SELECT NVL(SUM(ADP_DED),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = :NEW.APL_ID),
        APL_TOT_NETO = (SELECT NVL(SUM(APD_NETO),0) FROM ACS_DETALLE_PLANILLA D WHERE D.APL_ID = :NEW.APL_ID)
WHERE P.APL_ID = :NEW.APL_ID;
END;
/

-- =============================================
-- Trigger: TRG_AUDITORIA_PLANILLA
-- Audita cambios de estado en ACS_PLANILLA
-- Registra en ACS_BITACORA_PLANILLA
-- Fecha: 2025-11-09
-- =============================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_PLANILLA
AFTER INSERT OR UPDATE OF APL_ESTADO ON ACS_PLANILLA
FOR EACH ROW
DECLARE
v_accion VARCHAR2(30);
v_detalle VARCHAR2(200);
v_usuario_id NUMBER;
BEGIN
-- Obtener usuario actual (si existe sesión de aplicación)
BEGIN
    SELECT AUS_ID INTO v_usuario_id
    FROM ACS_USUARIO
    WHERE APE_ID = (
    SELECT APE_ID FROM ACS_PERSONA WHERE APE_EMAIL = USER || '@sistema.com'
    )
    AND ROWNUM = 1;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    v_usuario_id := NULL;
END;

-- Determinar acción y detalle
IF INSERTING THEN
    v_accion := 'CREAR';
    v_detalle := 'Planilla creada en estado: ' || :NEW.APL_ESTADO;
    
ELSIF UPDATING THEN
    v_accion := 'CAMBIO_ESTADO';
    v_detalle := 'Estado cambió de ' || :OLD.APL_ESTADO || ' a ' || :NEW.APL_ESTADO;
    
    -- Registrar acciones específicas según el nuevo estado
    CASE :NEW.APL_ESTADO
    WHEN 'APROBADA' THEN
        v_accion := 'APROBAR';
    WHEN 'PROCESADA' THEN
        v_accion := 'PROCESAR';
    WHEN 'NOTIFICADA' THEN
        v_accion := 'NOTIFICAR';
    ELSE
        v_accion := 'MODIFICAR';
    END CASE;
END IF;

-- Insertar en bitácora
INSERT INTO ACS_BITACORA_PLANILLA (
    ABP_ACCION,
    ABP_DETALLE,
    ABP_FECHA_CREACION,
    APL_ID,
    AUS_ID
) VALUES (
    v_accion,
    v_detalle,
    SYSTIMESTAMP,
    :NEW.APL_ID,
    v_usuario_id
);

EXCEPTION
WHEN OTHERS THEN
    -- No fallar la operación principal si hay error en auditoría
    DBMS_OUTPUT.PUT_LINE('Error en bitácora planilla: ' || SQLERRM);
END;
/
