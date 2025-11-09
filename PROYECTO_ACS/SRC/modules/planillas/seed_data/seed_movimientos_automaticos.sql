-- =============================================================================
-- Seed Data: Movimientos Automáticos y Rangos Salariales
-- =============================================================================
-- Descripción: Carga los movimientos automáticos estándar de Costa Rica:
--   - CCSS (9% sobre bruto)
--   - Renta con rangos progresivos
--   - Caja (deducción administrativa)
--   - Banco Popular (1.5% sobre bruto)
--   - Incentivos/Bonos (ingresos variables)
-- =============================================================================

SET SERVEROUTPUT ON;

-- Limpiar datos anteriores (solo si existen)
DELETE FROM ACS_TIPO_MOV_RANGO;
DELETE FROM ACS_TIPO_MOV;
COMMIT;

-- =============================================================================
-- 1️⃣ MOVIMIENTOS DE DEDUCCIÓN
-- =============================================================================

-- CCSS (9% sobre bruto) - Aplica a todos
INSERT INTO ACS_TIPO_MOV (
    ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A,
    ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO,
    ATM_ES_AUTOMATICO, ATM_PRIORIDAD, ATM_ESTADO, ATM_REGLA
) VALUES (
    'CCSS', 'Caja Costarricense Seguro Social', 'DEDUCCION', 'AMBOS',
    'PORCENTAJE', 'BRUTO', 9.00, NULL,
    1, 1, 'ACTIVO', NULL
);

-- Renta (con rangos progresivos) - Aplica a todos
INSERT INTO ACS_TIPO_MOV (
    ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A,
    ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO,
    ATM_ES_AUTOMATICO, ATM_PRIORIDAD, ATM_ESTADO, ATM_REGLA
) VALUES (
    'RENTA', 'Impuesto sobre la Renta', 'DEDUCCION', 'AMBOS',
    'PORCENTAJE', 'BRUTO', NULL, NULL,
    1, 2, 'ACTIVO', 
    '{"tipo": "progresivo", "nota": "Aplicar rangos salariales según tabla Ministerio de Hacienda"}'
);

-- Caja (2.5% sobre bruto) - Solo administrativos
INSERT INTO ACS_TIPO_MOV (
    ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A,
    ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO,
    ATM_ES_AUTOMATICO, ATM_PRIORIDAD, ATM_ESTADO, ATM_REGLA
) VALUES (
    'CAJA', 'Aporte Caja de Ande', 'DEDUCCION', 'ADMINISTRATIVO',
    'PORCENTAJE', 'BRUTO', 2.50, NULL,
    1, 3, 'ACTIVO', NULL
);

-- Banco Popular (1.5% sobre bruto) - Aplica a todos
INSERT INTO ACS_TIPO_MOV (
    ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A,
    ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO,
    ATM_ES_AUTOMATICO, ATM_PRIORIDAD, ATM_ESTADO, ATM_REGLA
) VALUES (
    'BANCO_POPULAR', 'Cuota Banco Popular', 'DEDUCCION', 'AMBOS',
    'PORCENTAJE', 'BRUTO', 1.50, NULL,
    1, 4, 'ACTIVO', NULL
);

-- =============================================================================
-- 2️⃣ MOVIMIENTOS DE INGRESO (para médicos principalmente)
-- =============================================================================

-- Turnos realizados (calculado desde ACS_DETALLE_MENSUAL)
INSERT INTO ACS_TIPO_MOV (
    ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A,
    ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO,
    ATM_ES_AUTOMATICO, ATM_PRIORIDAD, ATM_ESTADO, ATM_REGLA
) VALUES (
    'TURNOS', 'Pago por Turnos Realizados', 'INGRESO', 'MEDICO',
    'PERSONALIZADA', 'HORAS', NULL, NULL,
    1, 5, 'ACTIVO',
    '{"calculo": "Sumar ATU_PAGO de turnos en ACS_DETALLE_MENSUAL según ATU_TIPO_PAGO (HORAS o TURNO)"}'
);

-- Procedimientos realizados
INSERT INTO ACS_TIPO_MOV (
    ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A,
    ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO,
    ATM_ES_AUTOMATICO, ATM_PRIORIDAD, ATM_ESTADO, ATM_REGLA
) VALUES (
    'PROCEDIMIENTOS', 'Pago por Procedimientos', 'INGRESO', 'MEDICO',
    'PERSONALIZADA', 'PROCEDIMIENTOS', NULL, NULL,
    1, 6, 'ACTIVO',
    '{"calculo": "Sumar valores de ACS_PROC_APLICADO para el médico en el mes"}'
);

-- Incentivos/Bonos (manual, pero estructura lista)
INSERT INTO ACS_TIPO_MOV (
    ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A,
    ATM_MODO, ATM_BASE, ATM_PORC, ATM_MONTO_FIJO,
    ATM_ES_AUTOMATICO, ATM_PRIORIDAD, ATM_ESTADO, ATM_REGLA
) VALUES (
    'INCENTIVO', 'Incentivos y Bonos', 'INGRESO', 'AMBOS',
    'FIJO', 'SALARIO_BASE', NULL, NULL,
    0, 7, 'ACTIVO', 
    '{"tipo": "manual", "nota": "Monto definido por supervisor"}'
);

-- =============================================================================
-- 3️⃣ RANGOS PROGRESIVOS PARA RENTA (según tabla Hacienda CR 2024)
-- =============================================================================

DECLARE
    v_renta_id NUMBER;
BEGIN
    -- Obtener el ID de RENTA
    SELECT ATM_ID INTO v_renta_id
    FROM ACS_TIPO_MOV
    WHERE ATM_COD = 'RENTA';
    
    -- Rango 1: ₡0 - ₡941,000 → 0% (exento)
    INSERT INTO ACS_TIPO_MOV_RANGO (
        ATM_ID, ATMR_RANGO_MIN, ATMR_RANGO_MAX, 
        ATMR_PORCENTAJE, ATMR_MONTO_FIJO, ATMR_ESTADO
    ) VALUES (
        v_renta_id, 0, 941000, 0, NULL, 1
    );
    
    -- Rango 2: ₡941,001 - ₡1,381,000 → 10%
    INSERT INTO ACS_TIPO_MOV_RANGO (
        ATM_ID, ATMR_RANGO_MIN, ATMR_RANGO_MAX,
        ATMR_PORCENTAJE, ATMR_MONTO_FIJO, ATMR_ESTADO
    ) VALUES (
        v_renta_id, 941001, 1381000, 10, NULL, 1
    );
    
    -- Rango 3: ₡1,381,001 - ₡2,423,000 → 15%
    INSERT INTO ACS_TIPO_MOV_RANGO (
        ATM_ID, ATMR_RANGO_MIN, ATMR_RANGO_MAX,
        ATMR_PORCENTAJE, ATMR_MONTO_FIJO, ATMR_ESTADO
    ) VALUES (
        v_renta_id, 1381001, 2423000, 15, NULL, 1
    );
    
    -- Rango 4: ₡2,423,001 - ₡4,845,000 → 20%
    INSERT INTO ACS_TIPO_MOV_RANGO (
        ATM_ID, ATMR_RANGO_MIN, ATMR_RANGO_MAX,
        ATMR_PORCENTAJE, ATMR_MONTO_FIJO, ATMR_ESTADO
    ) VALUES (
        v_renta_id, 2423001, 4845000, 20, NULL, 1
    );
    
    -- Rango 5: ₡4,845,001+ → 25%
    INSERT INTO ACS_TIPO_MOV_RANGO (
        ATM_ID, ATMR_RANGO_MIN, ATMR_RANGO_MAX,
        ATMR_PORCENTAJE, ATMR_MONTO_FIJO, ATMR_ESTADO
    ) VALUES (
        v_renta_id, 4845001, 999999999, 25, NULL, 1
    );
    
    COMMIT;
END;
/

COMMIT;

-- =============================================================================
-- 4️⃣ VERIFICACIÓN
-- =============================================================================

DBMS_OUTPUT.PUT_LINE('========================================');
DBMS_OUTPUT.PUT_LINE('✅ SEED DATA CARGADO EXITOSAMENTE');
DBMS_OUTPUT.PUT_LINE('========================================');
DBMS_OUTPUT.PUT_LINE('');

-- Mostrar movimientos cargados
DBMS_OUTPUT.PUT_LINE('📋 MOVIMIENTOS AUTOMÁTICOS:');
FOR rec IN (
    SELECT ATM_COD, ATM_NOMBRE, ATM_NATURALEZA, ATM_APLICA_A, 
           ATM_MODO, ATM_PORC, ATM_PRIORIDAD
    FROM ACS_TIPO_MOV
    ORDER BY ATM_PRIORIDAD
) LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || rec.ATM_COD || ' - ' || rec.ATM_NOMBRE || 
                         ' (' || rec.ATM_NATURALEZA || ', ' || rec.ATM_APLICA_A || ')');
END LOOP;

DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE('💰 RANGOS DE RENTA (progresivos):');
FOR rec IN (
    SELECT ATMR_RANGO_MIN, ATMR_RANGO_MAX, ATMR_PORCENTAJE
    FROM ACS_TIPO_MOV_RANGO
    WHERE ATM_ID = 2
    ORDER BY ATMR_RANGO_MIN
) LOOP
    DBMS_OUTPUT.PUT_LINE('  ₡' || TO_CHAR(rec.ATMR_RANGO_MIN, '999G999G999') || 
                         ' - ₡' || TO_CHAR(rec.ATMR_RANGO_MAX, '999G999G999') || 
                         ' → ' || rec.ATMR_PORCENTAJE || '%');
END LOOP;

DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE('========================================');
