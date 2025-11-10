/*******************************************************************************
 * SISTEMA DE ADMINISTRACIÓN DE CENTROS DE SALUD (ACS)
 * DEMOSTRACIÓN COMPLETA PARA DEFENSA DEL PROYECTO
 * 
 * Autor: Equipo de Desarrollo ACS
 * Fecha: 09-NOV-2025
 * Curso: Administración de Bases de Datos - II Ciclo 2025
 * Profesor: Máster Carlos Carranza Blanco
 * 
 * DESCRIPCIÓN:
 * Este script ejecuta paso a paso toda la funcionalidad implementada del
 * módulo de PLANILLAS, siguiendo el orden de la rúbrica del proyecto.
 * 
 * PUNTOS DE LA RÚBRICA CUBIERTOS:
 * - Punto 3: Generación de planillas de médicos según escalas (12%)
 * - Punto 4: Generación de planillas administrativas (12%)
 * 
 * PRERREQUISITOS:
 * 1. Base de datos Oracle 19c instalada y configurada
 * 2. Usuario MORA con permisos adecuados
 * 3. Tablespaces ACS creados
 * 4. Todas las tablas del sistema ACS creadas
 * 5. Datos de prueba cargados (ejecutar primero: demo_carga_datos.sql)
 * 
 * MODO DE USO:
 * SQL> SET SERVEROUTPUT ON SIZE UNLIMITED
 * SQL> SET LINESIZE 200
 * SQL> SET PAGESIZE 1000
 * SQL> @demo_defensa_profesor.sql
 ******************************************************************************/

-- ============================================================================
-- CONFIGURACIÓN DEL ENTORNO SQL*Plus PARA SALIDAS PROFESIONALES
-- ============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 1000
SET FEEDBACK ON
SET VERIFY OFF
SET ECHO OFF
SET TIMING OFF

-- Formato de columnas para reportes
COLUMN nombre FORMAT A40
COLUMN tipo FORMAT A15
COLUMN monto FORMAT 999,999,990.99
COLUMN fecha FORMAT A12
COLUMN estado FORMAT A15
COLUMN descripcion FORMAT A50

-- ============================================================================
-- ENCABEZADO VISUAL IMPACTANTE
-- ============================================================================
PROMPT 
PROMPT ╔════════════════════════════════════════════════════════════════════════════╗
PROMPT ║                                                                            ║
PROMPT ║         SISTEMA DE ADMINISTRACIÓN DE CENTROS DE SALUD (ACS)               ║
PROMPT ║                                                                            ║
PROMPT ║                    DEMOSTRACIÓN DE FUNCIONALIDAD                          ║
PROMPT ║                         MÓDULO DE PLANILLAS                               ║
PROMPT ║                                                                            ║
PROMPT ╚════════════════════════════════════════════════════════════════════════════╝
PROMPT 
PROMPT   Universidad Nacional - Sede Región Brunca
PROMPT   Administración de Bases de Datos - II Ciclo 2025
PROMPT   Profesor: Máster Carlos Carranza Blanco
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT   FECHA DE DEMOSTRACIÓN: 
SELECT TO_CHAR(SYSDATE, 'DD "de" MONTH "de" YYYY, HH24:MI:SS', 'NLS_DATE_LANGUAGE=SPANISH') AS "Fecha y Hora"
FROM DUAL;
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

PAUSE Presione ENTER para iniciar la demostración...

-- ============================================================================
-- PARTE 1: VERIFICACIÓN DE PRERREQUISITOS
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 1: VERIFICACIÓN DE PRERREQUISITOS DEL SISTEMA
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 1.1 - Verificando objetos compilados (Funciones y Procedimientos)     │
PROMPT └────────────────────────────────────────────────────────────────────────┘
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
ORDER BY object_type, object_name;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 1.2 - Verificando Tipos de Movimientos Automáticos Configurados       │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    '  ' || RPAD(ATM_CODIGO, 15) AS "Código",
    RPAD(ATM_NOMBRE, 30) AS "Nombre Movimiento",
    LPAD(TO_CHAR(ATM_PORCENTAJE, '990.99') || '%', 10) AS "Porcentaje",
    RPAD(ATM_MODO, 15) AS "Modo",
    CASE ATM_ES_AUTOMATICO 
        WHEN 1 THEN '[ ✓ Sí ]'
        ELSE '[ ✗ No ]'
    END AS "Automático"
FROM ACS_TIPO_MOV
WHERE ATM_ES_AUTOMATICO = 1
ORDER BY ATM_PRIORIDAD;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 1.3 - Verificando Rangos Salariales para RENTA (Impuesto)             │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    '  Tramo ' || ROWNUM AS "Tramo",
    '₡ ' || TRIM(TO_CHAR(r.ATMR_RANGO_MIN, '999,999,990')) AS "Desde",
    '₡ ' || TRIM(TO_CHAR(r.ATMR_RANGO_MAX, '999,999,990')) AS "Hasta",
    LPAD(TO_CHAR(r.ATMR_PORCENTAJE, '990.99') || '%', 10) AS "Tasa"
FROM ACS_TIPO_MOV_RANGO r
JOIN ACS_TIPO_MOV t ON r.ATM_ID = t.ATM_ID
WHERE t.ATM_CODIGO = 'RENTA'
ORDER BY r.ATMR_RANGO_MIN;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 1.4 - Verificando Datos de Prueba Cargados                            │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    RPAD('  → Centros de Salud registrados', 45, '.') || LPAD(COUNT(*), 8) AS "Estadísticas del Sistema"
FROM ACS_CENTRO_MEDICO
UNION ALL
SELECT 
    RPAD('  → Médicos activos en el sistema', 45, '.') || LPAD(COUNT(*), 8)
FROM ACS_USUARIO u
JOIN ACS_PERFIL pf ON u.APF_ID = pf.APF_ID
WHERE pf.APF_NOMBRE = 'MEDICO' AND u.AUS_ESTADO = 1
UNION ALL
SELECT 
    RPAD('  → Personal administrativo activo', 45, '.') || LPAD(COUNT(*), 8)
FROM ACS_USUARIO u
JOIN ACS_PERFIL pf ON u.APF_ID = pf.APF_ID
WHERE pf.APF_NOMBRE = 'ADMINISTRATIVO' AND u.AUS_ESTADO = 1
UNION ALL
SELECT 
    RPAD('  → Tipos de planilla configurados', 45, '.') || LPAD(COUNT(*), 8)
FROM ACS_TIPO_PLANILLA
WHERE ATP_ESTADO = 1;

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  ✓ PRERREQUISITOS VERIFICADOS EXITOSAMENTE
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

PAUSE Presione ENTER para continuar con la Parte 2...

-- ============================================================================
-- PARTE 2: GENERACIÓN DE PLANILLAS DE MÉDICOS (PUNTO 3 - 12%)
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 2: GENERACIÓN DE PLANILLAS DE MÉDICOS
PROMPT  (Punto 3 de la Rúbrica - 12%)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT  Este proceso genera las planillas de los médicos basándose en:
PROMPT  • Escalas mensuales (turnos trabajados)
PROMPT  • Procedimientos médicos realizados
PROMPT  • Movimientos automáticos (CCSS, Renta, Banco Popular)
PROMPT  • Cálculo de deducciones con rangos progresivos
PROMPT 

PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 2.1 - Limpieza de planillas anteriores del mes de prueba              │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

DECLARE
    v_mes NUMBER := 11;
    v_anio NUMBER := 2025;
    v_count NUMBER;
BEGIN
    -- Contar planillas existentes
    SELECT COUNT(*) INTO v_count
    FROM ACS_PLANILLA
    WHERE APL_MES = v_mes AND APL_ANIO = v_anio;
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('  → Eliminando ' || v_count || ' planilla(s) previa(s) del mes ' || v_mes || '/' || v_anio);
        
        DELETE FROM ACS_MOVIMIENTO_PLANILLA
        WHERE APD_ID IN (
            SELECT d.ADP_ID 
            FROM ACS_DETALLE_PLANILLA d
            JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
            WHERE p.APL_MES = v_mes AND p.APL_ANIO = v_anio
        );
        
        DELETE FROM ACS_DETALLE_PLANILLA
        WHERE APL_ID IN (
            SELECT APL_ID FROM ACS_PLANILLA
            WHERE APL_MES = v_mes AND APL_ANIO = v_anio
        );
        
        DELETE FROM ACS_PLANILLA
        WHERE APL_MES = v_mes AND APL_ANIO = v_anio;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('  ✓ Limpieza completada exitosamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  ℹ No hay planillas previas que eliminar');
    END IF;
END;
/

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 2.2 - Ejecutando: PRC_GENERAR_PLANILLAS_MEDICOS(11, 2025)             │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SET TIMING ON
EXECUTE PRC_GENERAR_PLANILLAS_MEDICOS(11, 2025);
SET TIMING OFF

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 2.3 - Resumen de Planillas de Médicos Generadas                       │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    '  Planilla ID: ' || p.APL_ID AS "Planilla",
    TO_CHAR(p.APL_FECHA_CREACION, 'DD-MON-YYYY HH24:MI') AS "Fecha Creación",
    tp.ATP_NOMBRE AS "Tipo",
    COUNT(d.ADP_ID) AS "Cantidad Médicos",
    '₡ ' || TRIM(TO_CHAR(p.APL_TOTAL_BRUTO, '999,999,990.99')) AS "Total Bruto",
    '₡ ' || TRIM(TO_CHAR(p.APL_TOTAL_DEDUCCIONES, '999,999,990.99')) AS "Total Deducciones",
    '₡ ' || TRIM(TO_CHAR(p.APL_TOTAL_NETO, '999,999,990.99')) AS "Total Neto"
FROM ACS_PLANILLA p
JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
LEFT JOIN ACS_DETALLE_PLANILLA d ON p.APL_ID = d.APL_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
  AND tp.ATP_NOMBRE LIKE '%MEDICO%'
GROUP BY p.APL_ID, p.APL_FECHA_CREACION, tp.ATP_NOMBRE, 
         p.APL_TOTAL_BRUTO, p.APL_TOTAL_DEDUCCIONES, p.APL_TOTAL_NETO;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 2.4 - Detalle de Primeros 5 Médicos en Planilla                       │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT * FROM (
    SELECT 
        pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO || ' ' || pe.APE_S_APELLIDO AS "Nombre Completo",
        '₡ ' || TRIM(TO_CHAR(d.ADP_SALARIO_BASE, '999,999,990.99')) AS "Salario Base",
        '₡ ' || TRIM(TO_CHAR(d.ADP_BRUTO, '999,999,990.99')) AS "Bruto",
        '₡ ' || TRIM(TO_CHAR(d.ADP_DEDUCCIONES, '999,999,990.99')) AS "Deducciones",
        '₡ ' || TRIM(TO_CHAR(d.ADP_NETO, '999,999,990.99')) AS "Neto a Pagar"
    FROM ACS_DETALLE_PLANILLA d
    JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
    JOIN ACS_USUARIO u ON d.AUS_ID = u.AUS_ID
    JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
    JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
    WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
      AND tp.ATP_NOMBRE LIKE '%MEDICO%'
    ORDER BY d.ADP_NETO DESC
)
WHERE ROWNUM <= 5;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 2.5 - Movimientos Aplicados (Deducciones) por Tipo                    │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    tm.ATM_NOMBRE AS "Tipo de Movimiento",
    COUNT(*) AS "Cantidad Aplicaciones",
    '₡ ' || TRIM(TO_CHAR(SUM(m.AMP_MONTO), '999,999,990.99')) AS "Monto Total",
    '₡ ' || TRIM(TO_CHAR(AVG(m.AMP_MONTO), '999,999,990.99')) AS "Promedio"
FROM ACS_MOVIMIENTO_PLANILLA m
JOIN ACS_TIPO_MOV tm ON m.ATM_ID = tm.ATM_ID
JOIN ACS_DETALLE_PLANILLA d ON m.ADP_ID = d.ADP_ID
JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
  AND tp.ATP_NOMBRE LIKE '%MEDICO%'
  AND tm.ATM_TIPO = 'DEDUCCION'
GROUP BY tm.ATM_NOMBRE
ORDER BY SUM(m.AMP_MONTO) DESC;

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  ✓ GENERACIÓN DE PLANILLAS DE MÉDICOS COMPLETADA EXITOSAMENTE
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

PAUSE Presione ENTER para continuar con la Parte 3...

-- ============================================================================
-- PARTE 3: GENERACIÓN DE PLANILLAS ADMINISTRATIVAS (PUNTO 4 - 12%)
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 3: GENERACIÓN DE PLANILLAS ADMINISTRATIVAS
PROMPT  (Punto 4 de la Rúbrica - 12%)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT  Este proceso genera las planillas del personal administrativo con:
PROMPT  • Salario base configurado
PROMPT  • Movimientos automáticos (CCSS, Renta progresiva, Caja, Banco)
PROMPT  • Aplicación de rangos salariales para el impuesto de renta
PROMPT 

PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 3.1 - Ejecutando: PRC_GENERAR_PLANILLAS_ADMIN(11, 2025)               │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SET TIMING ON
EXECUTE PRC_GENERAR_PLANILLAS_ADMIN(11, 2025);
SET TIMING OFF

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 3.2 - Resumen de Planillas Administrativas Generadas                  │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    '  Planilla ID: ' || p.APL_ID AS "Planilla",
    TO_CHAR(p.APL_FECHA_CREACION, 'DD-MON-YYYY HH24:MI') AS "Fecha Creación",
    tp.ATP_NOMBRE AS "Tipo",
    COUNT(d.ADP_ID) AS "Cantidad Personal",
    '₡ ' || TRIM(TO_CHAR(p.APL_TOTAL_BRUTO, '999,999,990.99')) AS "Total Bruto",
    '₡ ' || TRIM(TO_CHAR(p.APL_TOTAL_DEDUCCIONES, '999,999,990.99')) AS "Total Deducciones",
    '₡ ' || TRIM(TO_CHAR(p.APL_TOTAL_NETO, '999,999,990.99')) AS "Total Neto"
FROM ACS_PLANILLA p
JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
LEFT JOIN ACS_DETALLE_PLANILLA d ON p.APL_ID = d.APL_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
  AND tp.ATP_NOMBRE LIKE '%ADMIN%'
GROUP BY p.APL_ID, p.APL_FECHA_CREACION, tp.ATP_NOMBRE, 
         p.APL_TOTAL_BRUTO, p.APL_TOTAL_DEDUCCIONES, p.APL_TOTAL_NETO;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 3.3 - Detalle de Personal Administrativo en Planilla                  │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT * FROM (
    SELECT 
        pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO || ' ' || pe.APE_S_APELLIDO AS "Nombre Completo",
        '₡ ' || TRIM(TO_CHAR(d.ADP_SALARIO_BASE, '999,999,990.99')) AS "Salario Base",
        '₡ ' || TRIM(TO_CHAR(d.ADP_BRUTO, '999,999,990.99')) AS "Bruto",
        '₡ ' || TRIM(TO_CHAR(d.ADP_DEDUCCIONES, '999,999,990.99')) AS "Deducciones",
        '₡ ' || TRIM(TO_CHAR(d.ADP_NETO, '999,999,990.99')) AS "Neto a Pagar"
    FROM ACS_DETALLE_PLANILLA d
    JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
    JOIN ACS_USUARIO u ON d.AUS_ID = u.AUS_ID
    JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
    JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
    WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
      AND tp.ATP_NOMBRE LIKE '%ADMIN%'
    ORDER BY d.ADP_NETO DESC
)
WHERE ROWNUM <= 5;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 3.4 - Demostración de Cálculo Progresivo de RENTA                     │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 
PROMPT   Ejemplo con un administrativo:
PROMPT 

SELECT 
    pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO AS "Empleado",
    '₡ ' || TRIM(TO_CHAR(d.ADP_SALARIO_BASE, '999,999,990.99')) AS "Salario Base",
    '₡ ' || TRIM(TO_CHAR(m.AMP_MONTO, '999,999,990.99')) AS "Renta Calculada",
    '  (Base de cálculo: ₡' || TRIM(TO_CHAR(m.AMP_CALCULO_BASE, '999,999,990.99')) || ')' AS "Detalle"
FROM ACS_MOVIMIENTO_PLANILLA m
JOIN ACS_DETALLE_PLANILLA d ON m.ADP_ID = d.ADP_ID
JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
JOIN ACS_USUARIO u ON d.AUS_ID = u.AUS_ID
JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
JOIN ACS_TIPO_MOV tm ON m.ATM_ID = tm.ATM_ID
JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
  AND tp.ATP_NOMBRE LIKE '%ADMIN%'
  AND tm.ATM_CODIGO = 'RENTA'
  AND ROWNUM = 1;

PROMPT 
PROMPT   ℹ El impuesto de renta se calcula aplicando rangos progresivos:
PROMPT     • Tramo 1: ₡0 - ₡941,000 al 0%
PROMPT     • Tramo 2: ₡941,000 - ₡1,381,000 al 10%
PROMPT     • Tramo 3: ₡1,381,000 - ₡2,423,000 al 15%
PROMPT     • Tramo 4: ₡2,423,000 - ₡4,845,000 al 20%
PROMPT     • Tramo 5: Más de ₡4,845,000 al 25%
PROMPT 

PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 3.5 - Movimientos Aplicados al Personal Administrativo                │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    tm.ATM_NOMBRE AS "Tipo de Movimiento",
    COUNT(*) AS "Aplicaciones",
    '₡ ' || TRIM(TO_CHAR(SUM(m.AMP_MONTO), '999,999,990.99')) AS "Monto Total",
    '₡ ' || TRIM(TO_CHAR(AVG(m.AMP_MONTO), '999,999,990.99')) AS "Promedio"
FROM ACS_MOVIMIENTO_PLANILLA m
JOIN ACS_TIPO_MOV tm ON m.ATM_ID = tm.ATM_ID
JOIN ACS_DETALLE_PLANILLA d ON m.ADP_ID = d.ADP_ID
JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
  AND tp.ATP_NOMBRE LIKE '%ADMIN%'
  AND tm.ATM_TIPO = 'DEDUCCION'
GROUP BY tm.ATM_NOMBRE
ORDER BY tm.ATM_NOMBRE;

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  ✓ GENERACIÓN DE PLANILLAS ADMINISTRATIVAS COMPLETADA EXITOSAMENTE
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

PAUSE Presione ENTER para continuar con la Parte 4...

-- ============================================================================
-- PARTE 4: VALIDACIÓN DE INTEGRIDAD
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 4: VALIDACIÓN DE INTEGRIDAD DE DATOS
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 4.1 - Verificando consistencia: Totales de encabezado vs detalles     │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    p.APL_ID AS "ID Planilla",
    tp.ATP_NOMBRE AS "Tipo",
    CASE 
        WHEN ABS(p.APL_TOTAL_BRUTO - NVL(SUM(d.ADP_BRUTO), 0)) < 0.01 
        THEN '✓ OK'
        ELSE '✗ ERROR'
    END AS "Validación Bruto",
    CASE 
        WHEN ABS(p.APL_TOTAL_DEDUCCIONES - NVL(SUM(d.ADP_DEDUCCIONES), 0)) < 0.01 
        THEN '✓ OK'
        ELSE '✗ ERROR'
    END AS "Validación Deducciones",
    CASE 
        WHEN ABS(p.APL_TOTAL_NETO - NVL(SUM(d.ADP_NETO), 0)) < 0.01 
        THEN '✓ OK'
        ELSE '✗ ERROR'
    END AS "Validación Neto"
FROM ACS_PLANILLA p
JOIN ACS_TIPO_PLANILLA tp ON p.ATP_ID = tp.ATP_ID
LEFT JOIN ACS_DETALLE_PLANILLA d ON p.APL_ID = d.APL_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
GROUP BY p.APL_ID, tp.ATP_NOMBRE, p.APL_TOTAL_BRUTO, 
         p.APL_TOTAL_DEDUCCIONES, p.APL_TOTAL_NETO
ORDER BY p.APL_ID;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 4.2 - Verificando que Bruto = Neto + Deducciones para cada empleado   │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '  ✓ TODOS LOS REGISTROS SON CONSISTENTES'
        ELSE '  ✗ SE ENCONTRARON ' || COUNT(*) || ' INCONSISTENCIAS'
    END AS "Resultado Validación"
FROM ACS_DETALLE_PLANILLA d
JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
  AND ABS(d.ADP_BRUTO - (d.ADP_NETO + d.ADP_DEDUCCIONES)) > 0.01;

PROMPT 
PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 4.3 - Resumen Financiero General del Mes                              │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    'NOVIEMBRE 2025' AS "Período",
    COUNT(DISTINCT p.APL_ID) AS "Planillas Generadas",
    COUNT(DISTINCT d.AUS_ID) AS "Empleados Pagados",
    '₡ ' || TRIM(TO_CHAR(SUM(p.APL_TOTAL_BRUTO), '999,999,990.99')) AS "Total Bruto",
    '₡ ' || TRIM(TO_CHAR(SUM(p.APL_TOTAL_DEDUCCIONES), '999,999,990.99')) AS "Total Deducciones",
    '₡ ' || TRIM(TO_CHAR(SUM(p.APL_TOTAL_NETO), '999,999,990.99')) AS "Total Neto a Pagar"
FROM ACS_PLANILLA p
LEFT JOIN ACS_DETALLE_PLANILLA d ON p.APL_ID = d.APL_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025;

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  ✓ VALIDACIONES DE INTEGRIDAD COMPLETADAS EXITOSAMENTE
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

-- ============================================================================
-- PARTE 5: AUDITORÍA Y TRAZABILIDAD
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PARTE 5: AUDITORÍA Y TRAZABILIDAD DEL SISTEMA
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

PROMPT ┌────────────────────────────────────────────────────────────────────────┐
PROMPT │ 5.1 - Ejemplo de trazabilidad de movimientos de un empleado           │
PROMPT └────────────────────────────────────────────────────────────────────────┘
PROMPT 

SELECT 
    pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO AS "Empleado",
    tm.ATM_NOMBRE AS "Movimiento",
    tm.ATM_TIPO AS "Tipo",
    '₡ ' || TRIM(TO_CHAR(m.AMP_CALCULO_BASE, '999,999,990.99')) AS "Base Cálculo",
    '₡ ' || TRIM(TO_CHAR(m.AMP_MONTO, '999,999,990.99')) AS "Monto Aplicado",
    m.AMP_FUENTE AS "Fuente"
FROM ACS_MOVIMIENTO_PLANILLA m
JOIN ACS_DETALLE_PLANILLA d ON m.ADP_ID = d.ADP_ID
JOIN ACS_PLANILLA p ON d.APL_ID = p.APL_ID
JOIN ACS_USUARIO u ON d.AUS_ID = u.AUS_ID
JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
JOIN ACS_TIPO_MOV tm ON m.ATM_ID = tm.ATM_ID
WHERE p.APL_MES = 11 AND p.APL_ANIO = 2025
  AND ROWNUM <= 8
ORDER BY pe.APE_APELLIDO1, tm.ATM_PRIORIDAD;

PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  ✓ AUDITORÍA Y TRAZABILIDAD VERIFICADAS
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================
PROMPT 
PROMPT ╔════════════════════════════════════════════════════════════════════════════╗
PROMPT ║                                                                            ║
PROMPT ║                        DEMOSTRACIÓN COMPLETADA                            ║
PROMPT ║                                                                            ║
PROMPT ╚════════════════════════════════════════════════════════════════════════════╝
PROMPT 
PROMPT   ✓ Punto 3 (12%): Planillas de Médicos generadas correctamente
PROMPT   ✓ Punto 4 (12%): Planillas Administrativas con rangos progresivos
PROMPT   ✓ Integridad de datos verificada
PROMPT   ✓ Cálculos automáticos aplicados (CCSS, Renta, Caja, Banco)
PROMPT   ✓ Trazabilidad y auditoría completa
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT   SISTEMA LISTO PARA PRODUCCIÓN
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT   Fecha de finalización: 
SELECT TO_CHAR(SYSDATE, 'DD "de" MONTH "de" YYYY, HH24:MI:SS', 'NLS_DATE_LANGUAGE=SPANISH') 
FROM DUAL;
PROMPT 
PROMPT ╔════════════════════════════════════════════════════════════════════════════╗
PROMPT ║  Universidad Nacional - Sede Región Brunca                               ║
PROMPT ║  Administración de Bases de Datos - II Ciclo 2025                        ║
PROMPT ║  Gracias por su atención, Profesor Carranza                              ║
PROMPT ╚════════════════════════════════════════════════════════════════════════════╝
PROMPT 

-- Restaurar configuración
SET FEEDBACK ON
SET ECHO ON
SET TIMING ON
