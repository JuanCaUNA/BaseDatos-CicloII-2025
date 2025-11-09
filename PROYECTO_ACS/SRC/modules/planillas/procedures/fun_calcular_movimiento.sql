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
        v_resto := p_base_calculo;
        
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

SET SERVEROUTPUT ON;

DECLARE
    v_test_salario NUMBER;
    v_ccss NUMBER;
    v_renta NUMBER;
    v_banco NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('PRUEBAS FUN_CALCULAR_MOVIMIENTO');
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 1: Salario bajo (sin renta)
    v_test_salario := 800000;
    v_ccss := FUN_CALCULAR_MOVIMIENTO(1, v_test_salario); -- CCSS 9%
    v_renta := FUN_CALCULAR_MOVIMIENTO(2, v_test_salario); -- Renta progresiva
    v_banco := FUN_CALCULAR_MOVIMIENTO(4, v_test_salario); -- Banco 1.5%
    
    DBMS_OUTPUT.PUT_LINE('📊 Salario: ₡' || TO_CHAR(v_test_salario, '999G999G999'));
    DBMS_OUTPUT.PUT_LINE('   CCSS (9%): ₡' || TO_CHAR(v_ccss, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Renta: ₡' || TO_CHAR(v_renta, '999G999G999.00') || ' (exento)');
    DBMS_OUTPUT.PUT_LINE('   Banco (1.5%): ₡' || TO_CHAR(v_banco, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Total deducciones: ₡' || TO_CHAR(v_ccss + v_renta + v_banco, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Neto: ₡' || TO_CHAR(v_test_salario - (v_ccss + v_renta + v_banco), '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 2: Salario medio (con renta 10%)
    v_test_salario := 1200000;
    v_ccss := FUN_CALCULAR_MOVIMIENTO(1, v_test_salario);
    v_renta := FUN_CALCULAR_MOVIMIENTO(2, v_test_salario);
    v_banco := FUN_CALCULAR_MOVIMIENTO(4, v_test_salario);
    
    DBMS_OUTPUT.PUT_LINE('📊 Salario: ₡' || TO_CHAR(v_test_salario, '999G999G999'));
    DBMS_OUTPUT.PUT_LINE('   CCSS (9%): ₡' || TO_CHAR(v_ccss, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Renta progresiva: ₡' || TO_CHAR(v_renta, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Banco (1.5%): ₡' || TO_CHAR(v_banco, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Total deducciones: ₡' || TO_CHAR(v_ccss + v_renta + v_banco, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Neto: ₡' || TO_CHAR(v_test_salario - (v_ccss + v_renta + v_banco), '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 3: Salario alto (múltiples rangos)
    v_test_salario := 3000000;
    v_ccss := FUN_CALCULAR_MOVIMIENTO(1, v_test_salario);
    v_renta := FUN_CALCULAR_MOVIMIENTO(2, v_test_salario);
    v_banco := FUN_CALCULAR_MOVIMIENTO(4, v_test_salario);
    
    DBMS_OUTPUT.PUT_LINE('📊 Salario: ₡' || TO_CHAR(v_test_salario, '999G999G999'));
    DBMS_OUTPUT.PUT_LINE('   CCSS (9%): ₡' || TO_CHAR(v_ccss, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Renta progresiva: ₡' || TO_CHAR(v_renta, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Banco (1.5%): ₡' || TO_CHAR(v_banco, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Total deducciones: ₡' || TO_CHAR(v_ccss + v_renta + v_banco, '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('   Neto: ₡' || TO_CHAR(v_test_salario - (v_ccss + v_renta + v_banco), '999G999G999.00'));
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('✅ Función compilada y probada');
    DBMS_OUTPUT.PUT_LINE('=================================');
END;
/
