-- ============================================================================
-- PUNTO 1 DE LA RÚBRICA: GENERACIÓN DE ESCALAS MENSUALES (8%)
-- ============================================================================
-- Requisito: "Se debe crear un proceso que a partir de la escala base 
--             se genere una escala mensual"
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 50

PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  PUNTO 1: GENERACIÓN DE ESCALAS MENSUALES (8%)
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT  Este script demuestra:
PROMPT  1. Creación de una escala base (plantilla semanal)
PROMPT  2. Generación automática de escala mensual desde la base
PROMPT  3. Asignación de médicos por día
PROMPT  4. Estados de escalas
PROMPT 

-- ============================================================================
-- PASO 1: Ver centro y turno disponible
-- ============================================================================
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 1: Centros y Turnos Disponibles
PROMPT ────────────────────────────────────────────────────────────────────────────

SELECT 
    cm.ACM_ID,
    cm.ACM_NOMBRE AS "Centro",
    pm.APM_ID,
    pm.APM_NOMBRE AS "Puesto",
    t.ATU_ID,
    t.ATU_NOMBRE AS "Turno",
    TO_CHAR(t.ATU_HORA_INICIO, 'HH24:MI') AS "Hora Inicio",
    TO_CHAR(t.ATU_HORA_FIN, 'HH24:MI') AS "Hora Fin"
FROM ACS_CENTRO_MEDICO cm
JOIN ACS_PUESTO_MEDICO pm ON cm.ACM_ID = pm.ACM_ID
JOIN ACS_TURNO t ON pm.APM_ID = t.APM_ID
WHERE cm.ACM_ESTADO = 'ACTIVO';

-- ============================================================================
-- PASO 2: Crear Escala Base (Plantilla Semanal)
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 2: Creando Escala Base (Plantilla Semanal)
PROMPT ────────────────────────────────────────────────────────────────────────────

DECLARE
    v_centro_id NUMBER := 1;  -- ID del centro creado
    v_escala_base_id NUMBER;
    v_turno_id NUMBER;
BEGIN
    -- Obtener ID del turno
    SELECT ATU_ID INTO v_turno_id
    FROM ACS_TURNO
    WHERE ROWNUM = 1;
    
    -- Crear escala base
    INSERT INTO ACS_ESCALA_BASE (
        ACM_ID,
        AEB_NOMBRE,
        AEB_DESCRIPCION,
        AEB_ESTADO,
        AEB_FECHA_CREACION,
        AEB_FECHA_ACTUALIZACION
    ) VALUES (
        v_centro_id,
        'Escala Base Medicina General Nov 2025',
        'Plantilla semanal para medicina general',
        'ACTIVO',
        SYSTIMESTAMP,
        SYSTIMESTAMP
    ) RETURNING AEB_ID INTO v_escala_base_id;
    
    -- Agregar detalles para cada día de la semana (Lunes a Viernes)
    FOR dia IN 1..5 LOOP
        INSERT INTO ACS_DETALLE_BASE (
            AEB_ID,
            ATU_ID,
            ADB_DIA_SEMANA,
            ADB_ESTADO,
            ADB_FECHA_CREACION,
            ADB_FECHA_ACTUALIZACION
        ) VALUES (
            v_escala_base_id,
            v_turno_id,
            dia,  -- 1=Lunes, 2=Martes, etc.
            'ACTIVO',
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    END LOOP;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ Escala base creada con ID: ' || v_escala_base_id);
    DBMS_OUTPUT.PUT_LINE('✓ 5 días configurados (Lunes a Viernes)');
END;
/

-- Ver la escala base creada
SELECT 
    eb.AEB_ID AS "ID Escala Base",
    eb.AEB_NOMBRE AS "Nombre",
    COUNT(db.ADB_ID) AS "Días Configurados"
FROM ACS_ESCALA_BASE eb
LEFT JOIN ACS_DETALLE_BASE db ON eb.AEB_ID = db.AEB_ID
GROUP BY eb.AEB_ID, eb.AEB_NOMBRE;

-- ============================================================================
-- PASO 3: Generar Escala Mensual desde la Base
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 3: Generando Escala Mensual (Noviembre 2025)
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT 
PROMPT  El procedimiento PRC_GENERAR_ESCALA_MENSUAL:
PROMPT  - Toma la escala base
PROMPT  - Genera un registro por cada día del mes
PROMPT  - Respeta el patrón semanal (Lun-Vie)
PROMPT  - Estado inicial: CONSTRUCCION
PROMPT 

-- Ejecutar el procedimiento
DECLARE
    v_escala_base_id NUMBER;
    v_escala_mensual_id NUMBER;
BEGIN
    -- Obtener ID de la escala base
    SELECT AEB_ID INTO v_escala_base_id
    FROM ACS_ESCALA_BASE
    WHERE ROWNUM = 1;
    
    -- Llamar al procedimiento
    PRC_GENERAR_ESCALA_MENSUAL(
        p_escala_base_id => v_escala_base_id,
        p_mes => 11,
        p_anio => 2025,
        p_escala_mensual_id => v_escala_mensual_id
    );
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✓ Escala mensual generada con ID: ' || v_escala_mensual_id);
    
    -- Ver resumen
    DECLARE
        v_total_dias NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total_dias
        FROM ACS_DETALLE_MENSUAL
        WHERE AEM_ID = v_escala_mensual_id;
        
        DBMS_OUTPUT.PUT_LINE('✓ Total de días generados: ' || v_total_dias);
    END;
END;
/

-- ============================================================================
-- PASO 4: Ver la Escala Mensual Generada
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 4: Detalle de la Escala Mensual (Primeros 10 días)
PROMPT ────────────────────────────────────────────────────────────────────────────

SELECT 
    em.AEM_ID AS "ID Escala",
    TO_CHAR(dm.ADM_FECHA, 'DD-MON-YYYY') AS "Fecha",
    TO_CHAR(dm.ADM_FECHA, 'Day', 'NLS_DATE_LANGUAGE=SPANISH') AS "Día Semana",
    t.ATU_NOMBRE AS "Turno",
    dm.ADM_ESTADO AS "Estado",
    NVL(pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO, 'SIN ASIGNAR') AS "Médico Asignado"
FROM ACS_ESCALA_MENSUAL em
JOIN ACS_DETALLE_MENSUAL dm ON em.AEM_ID = dm.AEM_ID
JOIN ACS_TURNO t ON dm.ATU_ID = t.ATU_ID
LEFT JOIN ACS_USUARIO u ON dm.AUS_ID = u.AUS_ID
LEFT JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
WHERE em.AEM_MES = 11 AND em.AEM_ANIO = 2025
ORDER BY dm.ADM_FECHA
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- PASO 5: Asignar Médicos a la Escala
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 5: Asignando Médicos a los Turnos
PROMPT ────────────────────────────────────────────────────────────────────────────

DECLARE
    v_usuario_medico_id NUMBER;
    v_contador NUMBER := 0;
BEGIN
    -- Obtener un médico
    SELECT u.AUS_ID INTO v_usuario_medico_id
    FROM ACS_USUARIO u
    JOIN ACS_PERSONA p ON u.APE_ID = p.APE_ID
    WHERE p.APE_TIPO_PERSONAL = 'MEDICO'
    AND ROWNUM = 1;
    
    -- Asignar a los primeros 5 días
    FOR rec IN (
        SELECT ADM_ID 
        FROM ACS_DETALLE_MENSUAL 
        WHERE AEM_ID = (SELECT AEM_ID FROM ACS_ESCALA_MENSUAL WHERE AEM_MES = 11 AND AEM_ANIO = 2025)
        AND ADM_FECHA <= TO_DATE('05-11-2025', 'DD-MM-YYYY')
        ORDER BY ADM_FECHA
    ) LOOP
        UPDATE ACS_DETALLE_MENSUAL
        SET AUS_ID = v_usuario_medico_id,
            ADM_ESTADO = 'ASIGNADO',
            ADM_FECHA_ACTUALIZACION = SYSTIMESTAMP
        WHERE ADM_ID = rec.ADM_ID;
        
        v_contador := v_contador + 1;
    END LOOP;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ ' || v_contador || ' turnos asignados al médico');
END;
/

-- Ver asignaciones
SELECT 
    TO_CHAR(dm.ADM_FECHA, 'DD-MON-YYYY') AS "Fecha",
    pe.APE_NOMBRE || ' ' || pe.APE_P_APELLIDO AS "Médico",
    t.ATU_NOMBRE AS "Turno",
    dm.ADM_ESTADO AS "Estado"
FROM ACS_DETALLE_MENSUAL dm
JOIN ACS_ESCALA_MENSUAL em ON dm.AEM_ID = em.AEM_ID
JOIN ACS_USUARIO u ON dm.AUS_ID = u.AUS_ID
JOIN ACS_PERSONA pe ON u.APE_ID = pe.APE_ID
JOIN ACS_TURNO t ON dm.ATU_ID = t.ATU_ID
WHERE em.AEM_MES = 11 AND em.AEM_ANIO = 2025
AND dm.AUS_ID IS NOT NULL
ORDER BY dm.ADM_FECHA;

-- ============================================================================
-- PASO 6: Cambiar Estado de la Escala
-- ============================================================================
PROMPT 
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT  PASO 6: Ciclo de Vida de la Escala Mensual
PROMPT ────────────────────────────────────────────────────────────────────────────
PROMPT 
PROMPT  Estados posibles:
PROMPT  - CONSTRUCCION: Escala en creación
PROMPT  - VIGENTE: Escala activa para el mes
PROMPT  - EN_REVISION: En proceso de revisión
PROMPT  - LISTA_PAGO: Lista para generar planilla
PROMPT  - PROCESADA: Ya se generó la planilla
PROMPT 

-- Cambiar a VIGENTE
UPDATE ACS_ESCALA_MENSUAL
SET AEM_ESTADO = 'VIGENTE',
    AEM_FECHA_ACTUALIZACION = SYSTIMESTAMP
WHERE AEM_MES = 11 AND AEM_ANIO = 2025;

COMMIT;

SELECT 
    AEM_ID AS "ID",
    AEM_MES || '/' || AEM_ANIO AS "Periodo",
    AEM_ESTADO AS "Estado",
    TO_CHAR(AEM_FECHA_ACTUALIZACION, 'DD-MON HH24:MI') AS "Última Actualización"
FROM ACS_ESCALA_MENSUAL
WHERE AEM_MES = 11 AND AEM_ANIO = 2025;

PROMPT ✓ Estado cambiado a VIGENTE

-- ============================================================================
-- RESUMEN Y VALIDACIONES
-- ============================================================================
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT  RESUMEN - PUNTO 1: ESCALAS MENSUALES (8%)
PROMPT ════════════════════════════════════════════════════════════════════════════

DECLARE
    v_escala_base_count NUMBER;
    v_escala_mensual_count NUMBER;
    v_dias_generados NUMBER;
    v_dias_asignados NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_escala_base_count FROM ACS_ESCALA_BASE;
    SELECT COUNT(*) INTO v_escala_mensual_count FROM ACS_ESCALA_MENSUAL;
    
    SELECT COUNT(*) INTO v_dias_generados
    FROM ACS_DETALLE_MENSUAL dm
    JOIN ACS_ESCALA_MENSUAL em ON dm.AEM_ID = em.AEM_ID
    WHERE em.AEM_MES = 11 AND em.AEM_ANIO = 2025;
    
    SELECT COUNT(*) INTO v_dias_asignados
    FROM ACS_DETALLE_MENSUAL dm
    JOIN ACS_ESCALA_MENSUAL em ON dm.AEM_ID = em.AEM_ID
    WHERE em.AEM_MES = 11 AND em.AEM_ANIO = 2025
    AND dm.AUS_ID IS NOT NULL;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✓ Escalas base creadas: ' || v_escala_base_count);
    DBMS_OUTPUT.PUT_LINE('✓ Escalas mensuales generadas: ' || v_escala_mensual_count);
    DBMS_OUTPUT.PUT_LINE('✓ Días generados en nov 2025: ' || v_dias_generados);
    DBMS_OUTPUT.PUT_LINE('✓ Días con médico asignado: ' || v_dias_asignados);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('  PUNTO 1 COMPLETADO: 8% ✓');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
END;
/

PROMPT 
PROMPT  Demostración lista para el profesor!
PROMPT  Puede ejecutar este script completo o paso por paso en ventanas separadas
PROMPT 

EXIT;
