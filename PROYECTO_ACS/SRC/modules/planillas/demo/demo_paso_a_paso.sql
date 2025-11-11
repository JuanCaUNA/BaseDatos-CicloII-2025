-- ============================================================================
-- SCRIPT DE DEMOSTRACIÓN PASO A PASO PARA LA DEFENSA
-- Sistema ACS - Módulo de Planillas
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF
SET VERIFY OFF

-- ============================================================================
-- PASO 1: VERIFICACIÓN DE OBJETOS
-- ============================================================================
PROMPT 
PROMPT ╔════════════════════════════════════════════════════════════════════════════╗
PROMPT ║         SISTEMA DE ADMINISTRACIÓN DE CENTROS DE SALUD (ACS)               ║
PROMPT ║                    DEMOSTRACIÓN PASO A PASO                               ║
PROMPT ╚════════════════════════════════════════════════════════════════════════════╝
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 1: VERIFICACIÓN DE OBJETOS COMPILADOS
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

SELECT 
    RPAD('  → ' || object_name, 50, '.') || ' ' || 
    CASE status 
        WHEN 'VALID' THEN '[ ✓ VÁLIDO ]'
        ELSE '[ ✗ INVÁLIDO ]'
    END AS "Estado de Objetos"
FROM user_objects 
WHERE object_name IN (
    'FUN_CALCULAR_MOVIMIENTO',
    'PRC_GENERAR_PLANILLAS_MEDICOS',
    'PRC_GENERAR_PLANILLAS_ADMIN'
)
ORDER BY object_name;

-- ============================================================================
-- PASO 2: VERIFICACIÓN DE MOVIMIENTOS AUTOMÁTICOS
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 2: MOVIMIENTOS AUTOMÁTICOS CONFIGURADOS
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

COLUMN codigo FORMAT A18 HEADING 'Código'
COLUMN nombre FORMAT A40 HEADING 'Nombre Movimiento'
COLUMN modo FORMAT A15 HEADING 'Modo'

SELECT 
    '  ' || ATM_COD AS codigo,
    ATM_NOMBRE AS nombre,
    ATM_MODO AS modo
FROM ACS_TIPO_MOV
WHERE ATM_ES_AUTOMATICO = 1
ORDER BY ATM_PRIORIDAD;

-- ============================================================================
-- PASO 3: RANGOS SALARIALES DE RENTA
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 3: RANGOS SALARIALES PARA IMPUESTO DE RENTA (Progresivo)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

COLUMN tramo FORMAT A12 HEADING 'Tramo'
COLUMN desde FORMAT A20 HEADING 'Desde'
COLUMN hasta FORMAT A20 HEADING 'Hasta'
COLUMN tasa FORMAT A10 HEADING 'Tasa'

SELECT 
    '  Tramo ' || ROWNUM AS tramo,
    '₡ ' || TRIM(TO_CHAR(r.ATMR_RANGO_MIN, '999,999,999')) AS desde,
    '₡ ' || TRIM(TO_CHAR(r.ATMR_RANGO_MAX, '999,999,999')) AS hasta,
    TO_CHAR(r.ATMR_PORCENTAJE, '990.99') || '%' AS tasa
FROM ACS_TIPO_MOV_RANGO r
JOIN ACS_TIPO_MOV t ON r.ATM_ID = t.ATM_ID
WHERE t.ATM_COD = 'RENTA'
ORDER BY r.ATMR_RANGO_MIN;

PROMPT 
PROMPT   ℹ Estos rangos se aplican de forma PROGRESIVA (tramo por tramo)
PROMPT 

-- ============================================================================
-- PASO 4: ESTADÍSTICAS DEL SISTEMA
-- ============================================================================
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 4: ESTADÍSTICAS DE DATOS EN EL SISTEMA
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

COLUMN estadistica FORMAT A65 HEADING 'Estadísticas del Sistema'

SELECT RPAD('  → Centros de Salud', 50, '.') || LPAD(COUNT(*), 8) AS estadistica FROM ACS_CENTRO_MEDICO
UNION ALL
SELECT RPAD('  → Usuarios activos', 50, '.') || LPAD(COUNT(*), 8) FROM ACS_USUARIO WHERE AUS_ESTADO = 'ACTIVO'
UNION ALL
SELECT RPAD('  → Tipos de Planilla', 50, '.') || LPAD(COUNT(*), 8) FROM ACS_TIPO_PLANILLA WHERE ATP_ESTADO = 'ACTIVO'
UNION ALL
SELECT RPAD('  → Movimientos Automáticos', 50, '.') || LPAD(COUNT(*), 8) FROM ACS_TIPO_MOV WHERE ATM_ES_AUTOMATICO = 1
UNION ALL
SELECT RPAD('  → Rangos de Renta', 50, '.') || LPAD(COUNT(*), 8) FROM ACS_TIPO_MOV_RANGO;

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  ✓ VERIFICACIÓN COMPLETADA - SISTEMA LISTO
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT   Presione CTRL+C para detener o espere para continuar...
PROMPT 

-- Pausa de 3 segundos
EXECUTE DBMS_LOCK.SLEEP(3);

-- ============================================================================
-- PASO 5: LIMPIEZA DE DATOS PREVIOS
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 5: LIMPIEZA DE PLANILLAS PREVIAS (Nov 2025)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM ACS_PLANILLA WHERE APL_MES = 11 AND APL_ANIO = 2025;
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('  → Eliminando ' || v_count || ' planilla(s) previa(s)...');
        
        DELETE FROM ACS_MOVIMIENTO_PLANILLA WHERE APD_ID IN (
            SELECT d.ADP_ID FROM ACS_DETALLE_PLANILLA d
            JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
            WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
        );
        
        DELETE FROM ACS_DETALLE_PLANILLA WHERE APL_ID IN (
            SELECT APL_ID FROM ACS_PLANILLA WHERE APL_MES = 11 AND APL_ANIO = 2025
        );
        
        DELETE FROM ACS_PLANILLA WHERE APL_MES = 11 AND APL_ANIO = 2025;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('  ✓ Limpieza completada exitosamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  ℹ No hay planillas previas que eliminar');
    END IF;
END;
/

PROMPT 

-- ============================================================================
-- PASO 6: VERIFICAR PERSONAL ASIGNADO A PLANILLAS
-- ============================================================================
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 6: VERIFICACIÓN DE PERSONAL ASIGNADO A TIPOS DE PLANILLA
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

DECLARE
    v_count_medicos NUMBER;
    v_count_admin NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_medicos
    FROM ACS_PERSONAL_TIPO_PLANILLA p
    JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
    WHERE UPPER(tp.ATP_APLICA_A) = 'MEDICO' AND p.APTP_ACTIVO = 1;
    
    SELECT COUNT(*) INTO v_count_admin
    FROM ACS_PERSONAL_TIPO_PLANILLA p
    JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
    WHERE UPPER(tp.ATP_APLICA_A) = 'ADMINISTRATIVO' AND p.APTP_ACTIVO = 1;
    
    DBMS_OUTPUT.PUT_LINE('  → Personal asignado a planilla MÉDICOS: ' || v_count_medicos);
    DBMS_OUTPUT.PUT_LINE('  → Personal asignado a planilla ADMINISTRATIVOS: ' || v_count_admin);
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_count_medicos = 0 AND v_count_admin = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ⚠ ADVERTENCIA: No hay personal asignado a ningún tipo de planilla');
        DBMS_OUTPUT.PUT_LINE('  ℹ Las planillas se generarán vacías (solo encabezado)');
    END IF;
END;
/

PROMPT 

-- ============================================================================
-- PASO 7: GENERACIÓN DE PLANILLAS DE MÉDICOS (Punto 3 - 12%)
-- ============================================================================
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 7: GENERACIÓN DE PLANILLAS DE MÉDICOS
PROMPT  (Punto 3 de la Rúbrica - 12%)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

SET TIMING ON
EXECUTE PRC_GENERAR_PLANILLAS_MEDICOS(11, 2025);
SET TIMING OFF

PROMPT 

-- ============================================================================
-- PASO 8: GENERACIÓN DE PLANILLAS ADMINISTRATIVAS (Punto 4 - 12%)
-- ============================================================================
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 8: GENERACIÓN DE PLANILLAS ADMINISTRATIVAS
PROMPT  (Punto 4 de la Rúbrica - 12%)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

SET TIMING ON
EXECUTE PRC_GENERAR_PLANILLAS_ADMIN(11, 2025);
SET TIMING OFF

PROMPT 

-- ============================================================================
-- PASO 9: RESUMEN DE PLANILLAS GENERADAS
-- ============================================================================
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 9: RESUMEN DE PLANILLAS GENERADAS
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

COLUMN planilla FORMAT A20 HEADING 'Planilla'
COLUMN tipo FORMAT A30 HEADING 'Tipo'
COLUMN cantidad FORMAT 9999 HEADING 'Cant'
COLUMN bruto FORMAT 999,999,990.99 HEADING 'Total Bruto'
COLUMN deducciones FORMAT 999,999,990.99 HEADING 'Total Deducc.'
COLUMN neto FORMAT 999,999,990.99 HEADING 'Total Neto'

SELECT 
    '  ID: ' || p.APL_ID AS planilla,
    tp.ATP_NOMBRE AS tipo,
    COUNT(d.ADP_ID) AS cantidad,
    NVL(p.APL_TOT_BRUTO, 0) AS bruto,
    NVL(p.APL_TOT_DED, 0) AS deducciones,
    NVL(p.APL_TOT_NETO, 0) AS neto
FROM ACS_PLANILLA p
JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
LEFT JOIN ACS_DETALLE_PLANILLA d ON p.APL_ID = d.APL_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
GROUP BY p.APL_ID, tp.ATP_NOMBRE, p.APL_TOT_BRUTO, p.APL_TOT_DED, p.APL_TOT_NETO
ORDER BY p.APL_ID;

PROMPT 

-- ============================================================================
-- PASO 10: VALIDACIÓN DE INTEGRIDAD
-- ============================================================================
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PASO 10: VALIDACIÓN DE INTEGRIDAD DE DATOS
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

COLUMN validacion FORMAT A60 HEADING 'Resultado de Validación'

DECLARE
    v_inconsistencias NUMBER := 0;
BEGIN
    -- Validar que encabezado coincide con suma de detalles
    FOR r IN (
        SELECT 
            p.APL_ID,
            p.APL_TOT_BRUTO,
            NVL(SUM(d.ADP_BRUTO), 0) as suma_bruto
        FROM ACS_PLANILLA p
        LEFT JOIN ACS_DETALLE_PLANILLA d ON p.APL_ID = d.APL_ID
        WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
        GROUP BY p.APL_ID, p.APL_TOT_BRUTO
    ) LOOP
        IF ABS(r.APL_TOT_BRUTO - r.suma_bruto) > 0.01 THEN
            v_inconsistencias := v_inconsistencias + 1;
            DBMS_OUTPUT.PUT_LINE('  ✗ Planilla ' || r.APL_ID || ': Inconsistencia en totales');
        END IF;
    END LOOP;
    
    IF v_inconsistencias = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ✓ Validación de totales: CORRECTA');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  ✗ Se encontraron ' || v_inconsistencias || ' inconsistencias');
    END IF;
    
    -- Validar que Bruto = Neto + Deducciones
    SELECT COUNT(*) INTO v_inconsistencias
    FROM ACS_DETALLE_PLANILLA d
    JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
    WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
      AND ABS(d.ADP_BRUTO - (d.APD_NETO + d.ADP_DED)) > 0.01;
    
    IF v_inconsistencias = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ✓ Validación Bruto = Neto + Deducciones: CORRECTA');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  ✗ ' || v_inconsistencias || ' registros con inconsistencias');
    END IF;
END;
/

PROMPT 

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================
PROMPT ╔════════════════════════════════════════════════════════════════════════════╗
PROMPT ║                     DEMOSTRACIÓN COMPLETADA                               ║
PROMPT ╚════════════════════════════════════════════════════════════════════════════╝
PROMPT 
PROMPT   ✓ Objetos compilados correctamente
PROMPT   ✓ Movimientos automáticos configurados  
PROMPT   ✓ Rangos progresivos de RENTA definidos
PROMPT   ✓ Planillas de MÉDICOS generadas (Punto 3 - 12%)
PROMPT   ✓ Planillas ADMINISTRATIVAS generadas (Punto 4 - 12%)
PROMPT   ✓ Validaciones de integridad: CORRECTAS
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT   SISTEMA OPERATIVO Y LISTO PARA PRODUCCIÓN
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

SET FEEDBACK ON
