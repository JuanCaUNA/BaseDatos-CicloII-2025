-- Configuracion
-- ! FUNCIONES
-- ! PROCEDIMIENTO
CREATE OR REPLACE PROCEDURE PRC_Asignar_Medico_Turno(
    p_adm_id IN NUMBER,
    p_ame_id IN NUMBER
) AS
    v_estado_turno VARCHAR2(20);
BEGIN
    -- Validar que el detalle mensual existe
    SELECT ADM_ESTADO_TURNO INTO v_estado_turno
    FROM ACS_DETALLE_MENSUAL
    WHERE ADM_ID = p_adm_id;

    -- Solo permite reasignar si el turno no está cancelado
    IF v_estado_turno = 'CANCELADO' THEN
        RAISE_APPLICATION_ERROR(-20010, 'No se puede reasignar un turno cancelado.');
    END IF;

    -- Actualizar el médico asignado y marcar como REEMPLAZADO
    UPDATE ACS_DETALLE_MENSUAL
    SET AME_ID = p_ame_id,
        ADM_ESTADO_TURNO = 'REEMPLAZADO'
    WHERE ADM_ID = p_adm_id;

    COMMIT;
END;
/ 

CREATE OR REPLACE PROCEDURE PRC_Consultar_Escalas(
    p_acm_id IN NUMBER,
    p_mes    IN NUMBER,
    p_anio   IN NUMBER
) AS
BEGIN
    -- Consulta encabezado de escala mensual
    FOR esc IN (
        SELECT AEM_ID, AEM_ESTADO
        FROM ACS_ESCALA_MENSUAL
        WHERE ACM_ID = p_acm_id AND AEM_MES = p_mes AND AEM_ANIO = p_anio
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Escala Mensual ID: ' || esc.AEM_ID || ' Estado: ' || esc.AEM_ESTADO);

        -- Consulta detalles de la escala mensual
        FOR det IN (
            SELECT ADM_ID, ADM_FECHA, ADM_ESTADO_TURNO, AME_ID, APM_ID, ATU_ID
            FROM ACS_DETALLE_MENSUAL
            WHERE AEM_ID = esc.AEM_ID
            ORDER BY ADM_FECHA, ATU_ID
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('  Detalle: ' || det.ADM_ID || ' Fecha: ' || TO_CHAR(det.ADM_FECHA,'DD-MM-YYYY') ||
                ' Turno: ' || det.ATU_ID || ' Médico: ' || det.AME_ID || ' Puesto: ' || det.APM_ID || ' Estado: ' || det.ADM_ESTADO_TURNO);
        END LOOP;
    END LOOP;
END;
/ 

CREATE OR REPLACE PROCEDURE PRC_Escala_Cambiar_Estado(
p_aem_id   IN NUMBER,
p_estado   IN VARCHAR2
) AS
v_estado_actual  VARCHAR2(30);
v_cnt_turnos     NUMBER;
BEGIN
SELECT AEM_ESTADO INTO v_estado_actual
FROM ACS_ESCALA_MENSUAL
WHERE AEM_ID = p_aem_id;

-- Validaciones mínimas según transición deseada
IF p_estado = 'VIGENTE' THEN
    NULL; -- aquí podrías validar que tenga detalles generados, etc.
ELSIF p_estado = 'EN REVISION' THEN
    NULL;
ELSIF p_estado = 'LISTA PARA PAGO' THEN
    -- Ejemplo: exigir al menos 1 detalle “CUMPLIDO” en el mes
    SELECT COUNT(*) INTO v_cnt_turnos
    FROM ACS_DETALLE_MENSUAL
    WHERE AEM_ID = p_aem_id
    AND NVL(ADM_ESTADO_TURNO,'CUMPLIDO') <> 'CANCELADO';
    IF v_cnt_turnos = 0 THEN
    RAISE_APPLICATION_ERROR(-20041,'Escala sin turnos válidos para lista de pago.');
    END IF;
ELSIF p_estado = 'PROCESADA' THEN
    NULL; -- la pondremos al aplicar planilla
ELSE
    RAISE_APPLICATION_ERROR(-20040,'Estado de escala no permitido.');
END IF;

UPDATE ACS_ESCALA_MENSUAL
SET AEM_ESTADO = p_estado
WHERE AEM_ID = p_aem_id;

COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE PRC_Escalas_Marcar_Lista_Pago(
p_mes   IN NUMBER,
p_anio  IN NUMBER,
p_acm_id IN NUMBER DEFAULT NULL
) AS
BEGIN
FOR r IN (
    SELECT AEM_ID
    FROM ACS_ESCALA_MENSUAL
    WHERE AEM_MES = p_mes
    AND AEM_ANIO = p_anio
    AND (p_acm_id IS NULL OR ACM_ID = p_acm_id)
    AND AEM_ESTADO IN ('VIGENTE','EN REVISION','CONSTRUCCION') -- candidatas
) LOOP
    PRC_Escala_Cambiar_Estado(r.AEM_ID, 'LISTA PARA PAGO');
END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE PRC_Escalas_Procesar_Por_Mes(
p_mes  IN NUMBER,
p_anio IN NUMBER
) AS
BEGIN
UPDATE ACS_ESCALA_MENSUAL
SET AEM_ESTADO = 'PROCESADA'
WHERE AEM_MES = p_mes
    AND AEM_ANIO = p_anio
    AND AEM_ESTADO = 'LISTA PARA PAGO';
COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE PRC_GENERAR_ESCALA_MENSUAL(
p_acm_id IN NUMBER,
p_mes    IN NUMBER,
p_anio   IN NUMBER
) AS
v_aem_id   NUMBER;
v_dias_mes NUMBER;
v_fecha    DATE;
BEGIN
-- Validar si ya existe escala mensual
SELECT COUNT(*) INTO v_aem_id
FROM ACS_ESCALA_MENSUAL
WHERE ACM_ID = p_acm_id AND AEM_MES = p_mes AND AEM_ANIO = p_anio;

IF v_aem_id > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Ya existe una escala mensual para ese centro, mes y año.');
END IF;

-- Crear encabezado
INSERT INTO ACS_ESCALA_MENSUAL (AEM_MES, AEM_ANIO, AEM_ESTADO, ACM_ID)
VALUES (p_mes, p_anio, 'CONSTRUCCION', p_acm_id)
RETURNING AEM_ID INTO v_aem_id;

-- Obtener cantidad de días del mes
SELECT (LAST_DAY(TO_DATE('01-'||LPAD(p_mes,2,'0')||'-'||p_anio,'DD-MM-YYYY'))
        - TO_DATE('01-'||LPAD(p_mes,2,'0')||'-'||p_anio,'DD-MM-YYYY') + 1)
INTO v_dias_mes
FROM DUAL;

-- Generar los días en la tabla de detalle (sin escala base)
FOR i IN 0..v_dias_mes-1 LOOP
    v_fecha := TO_DATE('01-'||LPAD(p_mes,2,'0')||'-'||p_anio,'DD-MM-YYYY') + i;

    INSERT INTO ACS_DETALLE_MENSUAL (
    ADM_OBSERVACIONES, ADM_FECHA, ADM_ESTADO_TURNO, ADM_HR_INICIO, ADM_HR_FIN,
    ADM_ESTADO, AEM_ID, AME_ID, APM_ID, ATU_ID
    )
    SELECT
    'Generado automáticamente', v_fecha, 'CUMPLIDO', ATU_HORA_INICIO, ATU_HORA_FIN,
    'ACTIVO', v_aem_id, AME_ID, APM_ID, ATU_ID
    FROM ACS_TURNO
    WHERE ATU_ESTADO = 'ACTIVO';
END LOOP;

COMMIT;
END;
/


-- ! TRIGGERS
CREATE OR REPLACE TRIGGER TRG_HIST_PROCEDIMIENTO
AFTER UPDATE OF APD_COSTO, APD_PAGO, APD_ESTADO ON ACS_PROCEDIMIENTO
FOR EACH ROW
DECLARE
    -- HELPERS PARA COMPARACIONES NULL-SAFE
    FUNCTION NUM_CHANGED(O NUMBER, N NUMBER) RETURN BOOLEAN IS
    BEGIN
        IF O IS NULL AND N IS NULL THEN
            RETURN FALSE;
        ELSIF O IS NULL AND N IS NOT NULL THEN
            RETURN TRUE;
        ELSIF O IS NOT NULL AND N IS NULL THEN
            RETURN TRUE;
        ELSE
            RETURN (O != N);
        END IF;
    END;

    FUNCTION STR_CHANGED(O VARCHAR2, N VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        IF O IS NULL AND N IS NULL THEN
            RETURN FALSE;
        ELSIF O IS NULL AND N IS NOT NULL THEN
            RETURN TRUE;
        ELSIF O IS NOT NULL AND N IS NULL THEN
            RETURN TRUE;
        ELSE
            RETURN NOT (O = N);
        END IF;
    END;
BEGIN
    -- SOLO ACTÚA SI HUBO CAMBIO REAL EN COSTO, PAGO O ESTADO
    IF NUM_CHANGED(:OLD.APD_COSTO, :NEW.APD_COSTO)
    OR NUM_CHANGED(:OLD.APD_PAGO,  :NEW.APD_PAGO)
    OR STR_CHANGED(:OLD.APD_ESTADO, :NEW.APD_ESTADO) THEN

        -- CIERRA HISTORIAL ABIERTO (SI EXISTE)
        UPDATE ACS_HISTORIAL_PROCEDIMIENTO H
        SET H.AHP_FECHA_FIN = SYSTIMESTAMP
        WHERE H.APD_ID = :OLD.APD_ID
        AND H.AHP_FECHA_FIN IS NULL
        AND EXISTS (
            SELECT 1
            FROM ACS_HISTORIAL_PROCEDIMIENTO HH
            WHERE HH.APD_ID = :OLD.APD_ID
                AND HH.AHP_FECHA_FIN IS NULL
        );

        -- INSERTA NUEVO REGISTRO DE HISTORIAL
        INSERT INTO ACS_HISTORIAL_PROCEDIMIENTO (
            AHP_NOMBRE,
            AHP_DESCRIPCION,
            AHP_COSTO,
            AHP_PAGO,
            AHP_ESTADO,
            AHP_FECHA_INICIO,
            AHP_FECHA_FIN,
            APD_ID
        ) VALUES (
            :NEW.APD_NOMBRE,
            :NEW.APD_DESCRIPCION,
            :NEW.APD_COSTO,
            :NEW.APD_PAGO,
            :NEW.APD_ESTADO,
            SYSTIMESTAMP,
            NULL,
            :NEW.APD_ID
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- FALLAR CLARAMENTE PARA EVITAR INCONSISTENCIA SILENCIOSA
        RAISE_APPLICATION_ERROR(-20030, 'TRG_HIST_PROCEDIMIENTO ERROR: ' || SQLERRM);
END;
/

CREATE OR REPLACE TRIGGER TRG_PROC_APLICADO_VALID
BEFORE INSERT OR UPDATE ON ACS_PROC_APLICADO
FOR EACH ROW
DECLARE
    V_COSTO NUMBER;
    V_PAGO  NUMBER;
BEGIN
    -- OBTIENE LOS VALORES DE COSTO Y PAGO SOLO SI ES UN INSERT
    IF INSERTING THEN
        BEGIN
            SELECT APD_COSTO, APD_PAGO
            INTO V_COSTO, V_PAGO
            FROM ACS_PROCEDIMIENTO
            WHERE APD_ID = :NEW.APD_ID;

            -- ASIGNA LOS VALORES POR DEFECTO SI SON NULL
            :NEW.APA_COSTO := COALESCE(:NEW.APA_COSTO, V_COSTO);
            :NEW.APA_PAGO := COALESCE(:NEW.APA_PAGO, V_PAGO);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20020, 'PROCEDIMIENTO NO ENCONTRADO.');
        END;
    END IF;

    -- VALIDACIONES OBLIGATORIAS
    IF :NEW.APA_COSTO IS NULL OR :NEW.APA_COSTO < 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'EL COSTO APLICADO NO PUEDE SER NULO NI NEGATIVO.');
    END IF;

    IF :NEW.APA_PAGO IS NULL OR :NEW.APA_PAGO < 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'EL PAGO AL MÉDICO NO PUEDE SER NULO NI NEGATIVO.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_UPDATE_ESTADO_ESCALA
FOR UPDATE OF ADM_ESTADO_TURNO ON ACS_DETALLE_MENSUAL
COMPOUND TRIGGER

TYPE T_NUM_TAB IS TABLE OF NUMBER;
G_AEM_IDS T_NUM_TAB := T_NUM_TAB();

/* BEFORE STATEMENT (OPCIONAL) */
BEFORE STATEMENT IS
BEGIN
    NULL;
END BEFORE STATEMENT;

/* AFTER EACH ROW: RECOLECTA AEM_IDS ÚNICOS AFECTADOS */
AFTER EACH ROW IS
    L_FOUND BOOLEAN;
BEGIN
    IF :NEW.AEM_ID IS NOT NULL THEN
    L_FOUND := FALSE;
    FOR I IN 1 .. G_AEM_IDS.COUNT LOOP
        IF G_AEM_IDS(I) = :NEW.AEM_ID THEN
        L_FOUND := TRUE;
        EXIT;
        END IF;
    END LOOP;

    IF NOT L_FOUND THEN
        G_AEM_IDS.EXTEND;
        G_AEM_IDS(G_AEM_IDS.COUNT) := :NEW.AEM_ID;
    END IF;
    END IF;
END AFTER EACH ROW;

/* AFTER STATEMENT: PROCESA CADA AEM_ID ÚNICO (EVITA MUTATING TABLE) */
AFTER STATEMENT IS
    V_TOTAL    NUMBER;
    V_COMPLETO NUMBER;
BEGIN
    FOR IDX IN 1 .. G_AEM_IDS.COUNT LOOP
    BEGIN
        SELECT COUNT(*),
            NVL(SUM(CASE WHEN NVL(ADM_ESTADO_TURNO,'') IN ('CUMPLIDO','REEMPLAZADO') THEN 1 ELSE 0 END), 0)
        INTO V_TOTAL, V_COMPLETO
        FROM ACS_DETALLE_MENSUAL
        WHERE AEM_ID = G_AEM_IDS(IDX);

        IF V_TOTAL > 0 AND V_TOTAL = V_COMPLETO THEN
        -- ACTUALIZA SOLO SI REALMENTE CAMBIA EL ESTADO
        UPDATE ACS_ESCALA_MENSUAL
        SET AEM_ESTADO = 'LISTA PARA PAGO'
        WHERE AEM_ID = G_AEM_IDS(IDX)
            AND NVL(AEM_ESTADO,'') <> 'LISTA PARA PAGO';
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        NULL; -- NO DEBERÍA PASAR
        WHEN OTHERS THEN
        -- LOG SIMPLE; NO QUEREMOS DEJAR QUE LA AUDITORÍA BLOQUEE LA OPERACIÓN
        DBMS_OUTPUT.PUT_LINE('TRG_UPDATE_ESTADO_ESCALA ERROR PARA AEM_ID=' || G_AEM_IDS(IDX) || ': ' || SQLERRM);
    END;
    END LOOP;

    -- LIMPIA LA COLECCIÓN (BUENA PRÁCTICA)
    G_AEM_IDS.DELETE;
END AFTER STATEMENT;

END TRG_UPDATE_ESTADO_ESCALA;
/

CREATE OR REPLACE TRIGGER TRG_AUDIT_DETALLE_MENSUAL
AFTER INSERT OR UPDATE OR DELETE ON ACS_DETALLE_MENSUAL
FOR EACH ROW
DECLARE
    V_CAMBIOS VARCHAR2(1000);
    
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF INSERTING THEN
        V_CAMBIOS := 'INSERT';
        INSERT INTO ACS_AUDITORIA_DETALLE_MENSUAL(
            AUM_OBSERVACIONES,
            AUM_FECHA,
            AUM_ESTADO_TURNO,
            AUM_HR_INICIO,
            AUM_HR_FIN,
            AUM_ESTADO,
            AUM_USUARIO,
            AUM_ACCION,
            AUM_CAMBIOS,
            AEM_ID,
            AME_ID,
            APM_ID,
            ATU_ID,
            ADM_ID
        ) VALUES (
            :NEW.ADM_OBSERVACIONES,
            SYSTIMESTAMP,
            :NEW.ADM_ESTADO_TURNO,
            :NEW.ADM_HR_INICIO,
            :NEW.ADM_HR_FIN,
            :NEW.ADM_ESTADO,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'INSERT',
            V_CAMBIOS,
            :NEW.AEM_ID,
            :NEW.AME_ID,
            :NEW.APM_ID,
            :NEW.ATU_ID,
            :NEW.ADM_ID
        );

    ELSIF UPDATING THEN
        V_CAMBIOS := '';
        
        IF NVL(:OLD.ADM_OBSERVACIONES,'') != NVL(:NEW.ADM_OBSERVACIONES,'') THEN
            V_CAMBIOS := V_CAMBIOS || 'ADM_OBSERVACIONES,';
        END IF;
        IF NVL(:OLD.ADM_ESTADO_TURNO,'') != NVL(:NEW.ADM_ESTADO_TURNO,'') THEN
            V_CAMBIOS := V_CAMBIOS || 'ADM_ESTADO_TURNO,';
        END IF;
        IF NVL(:OLD.ADM_HR_INICIO,SYSTIMESTAMP) != NVL(:NEW.ADM_HR_INICIO,SYSTIMESTAMP) THEN
            V_CAMBIOS := V_CAMBIOS || 'ADM_HR_INICIO,';
        END IF;
        IF NVL(:OLD.ADM_HR_FIN,SYSTIMESTAMP) != NVL(:NEW.ADM_HR_FIN,SYSTIMESTAMP) THEN
            V_CAMBIOS := V_CAMBIOS || 'ADM_HR_FIN,';
        END IF;
        IF NVL(:OLD.ADM_ESTADO,'') != NVL(:NEW.ADM_ESTADO,'') THEN
            V_CAMBIOS := V_CAMBIOS || 'ADM_ESTADO,';
        END IF;
        IF NVL(:OLD.AEM_ID,0) != NVL(:NEW.AEM_ID,0) THEN
            V_CAMBIOS := V_CAMBIOS || 'AEM_ID,';
        END IF;
        IF NVL(:OLD.AME_ID,0) != NVL(:NEW.AME_ID,0) THEN
            V_CAMBIOS := V_CAMBIOS || 'AME_ID,';
        END IF;
        IF NVL(:OLD.APM_ID,0) != NVL(:NEW.APM_ID,0) THEN
            V_CAMBIOS := V_CAMBIOS || 'APM_ID,';
        END IF;
        IF NVL(:OLD.ATU_ID,0) != NVL(:NEW.ATU_ID,0) THEN
            V_CAMBIOS := V_CAMBIOS || 'ATU_ID,';
        END IF;

        -- SOLO INSERTA SI HUBO CAMBIOS
        IF V_CAMBIOS IS NOT NULL AND V_CAMBIOS != '' THEN
            -- QUITA LA COMA FINAL
            V_CAMBIOS := RTRIM(V_CAMBIOS,',');

            INSERT INTO ACS_AUDITORIA_DETALLE_MENSUAL(
                AUM_OBSERVACIONES,
                AUM_FECHA,
                AUM_ESTADO_TURNO,
                AUM_HR_INICIO,
                AUM_HR_FIN,
                AUM_ESTADO,
                AUM_USUARIO,
                AUM_ACCION,
                AUM_CAMBIOS,
                AEM_ID,
                AME_ID,
                APM_ID,
                ATU_ID,
                ADM_ID
            ) VALUES (
                :NEW.ADM_OBSERVACIONES,
                SYSTIMESTAMP,
                :NEW.ADM_ESTADO_TURNO,
                :NEW.ADM_HR_INICIO,
                :NEW.ADM_HR_FIN,
                :NEW.ADM_ESTADO,
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'UPDATE',
                V_CAMBIOS,
                :NEW.AEM_ID,
                :NEW.AME_ID,
                :NEW.APM_ID,
                :NEW.ATU_ID,
                :NEW.ADM_ID
            );
        END IF;

    ELSIF DELETING THEN
        V_CAMBIOS := 'DELETE';
        INSERT INTO ACS_AUDITORIA_DETALLE_MENSUAL(
            AUM_OBSERVACIONES,
            AUM_FECHA,
            AUM_ESTADO_TURNO,
            AUM_HR_INICIO,
            AUM_HR_FIN,
            AUM_ESTADO,
            AUM_USUARIO,
            AUM_ACCION,
            AUM_CAMBIOS,
            AEM_ID,
            AME_ID,
            APM_ID,
            ATU_ID,
            ADM_ID
        ) VALUES (
            :OLD.ADM_OBSERVACIONES,
            SYSTIMESTAMP,
            :OLD.ADM_ESTADO_TURNO,
            :OLD.ADM_HR_INICIO,
            :OLD.ADM_HR_FIN,
            :OLD.ADM_ESTADO,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'DELETE',
            V_CAMBIOS,
            :OLD.AEM_ID,
            :OLD.AME_ID,
            :OLD.APM_ID,
            :OLD.ATU_ID,
            :OLD.ADM_ID
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- NO BLOQUEA LA OPERACIÓN PRINCIPAL
        DBMS_OUTPUT.PUT_LINE('ERROR EN AUDITORÍA DETALLE MENSUAL: ' || SQLERRM);
        NULL;
END;
/

-- ** AUDITORIA DETALLE MENSUAL
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_DETALLE_MENSUAL
AFTER INSERT OR UPDATE OR DELETE ON ACS_DETALLE_MENSUAL
FOR EACH ROW
DECLARE
v_accion VARCHAR2(10);
v_cambios VARCHAR2(100);
v_usuario VARCHAR2(50) := USER;
BEGIN
-- Determinar el tipo de acción
IF INSERTING THEN
    v_accion := 'INSERT';
    v_cambios := 'Nuevo detalle creado';
ELSIF UPDATING THEN
    v_accion := 'UPDATE';
    v_cambios := '';
    
    -- Detectar qué campos cambiaron
    IF :OLD.ADM_ESTADO_TURNO != :NEW.ADM_ESTADO_TURNO THEN
    v_cambios := v_cambios || 'ESTADO_TURNO, ';
    END IF;
    IF :OLD.ADM_HR_INICIO != :NEW.ADM_HR_INICIO THEN
    v_cambios := v_cambios || 'HR_INICIO, ';
    END IF;
    IF :OLD.ADM_HR_FIN != :NEW.ADM_HR_FIN THEN
    v_cambios := v_cambios || 'HR_FIN, ';
    END IF;
    IF :OLD.AME_ID != :NEW.AME_ID THEN
    v_cambios := v_cambios || 'MEDICO, ';
    END IF;
    IF :OLD.APM_ID != :NEW.APM_ID THEN
    v_cambios := v_cambios || 'PUESTO, ';
    END IF;
    IF :OLD.ATU_ID != :NEW.ATU_ID THEN
    v_cambios := v_cambios || 'TURNO, ';
    END IF;
    
    -- Remover última coma
    v_cambios := RTRIM(v_cambios, ', ');
    
ELSIF DELETING THEN
    v_accion := 'DELETE';
    v_cambios := 'Detalle eliminado';
END IF;

-- Insertar registro de auditoría
IF INSERTING OR UPDATING THEN
    INSERT INTO ACS_AUDITORIA_DETALLE_MENSUAL (
    AUM_OBSERVACIONES,
    AUM_FECHA,
    AUM_ESTADO_TURNO,
    AUM_HR_INICIO,
    AUM_HR_FIN,
    AUM_ESTADO,
    AUM_USUARIO,
    AUM_CAMBIOS,
    AUM_ACCION,
    AEM_ID,
    AME_ID,
    APM_ID,
    ATU_ID,
    ADM_ID
    ) VALUES (
    :NEW.ADM_OBSERVACIONES,
    :NEW.ADM_FECHA,
    :NEW.ADM_ESTADO_TURNO,
    :NEW.ADM_HR_INICIO,
    :NEW.ADM_HR_FIN,
    :NEW.ADM_ESTADO,
    v_usuario,
    v_cambios,
    v_accion,
    :NEW.AEM_ID,
    :NEW.AME_ID,
    :NEW.APM_ID,
    :NEW.ATU_ID,
    :NEW.ADM_ID
    );
ELSIF DELETING THEN
    INSERT INTO ACS_AUDITORIA_DETALLE_MENSUAL (
    AUM_OBSERVACIONES,
    AUM_FECHA,
    AUM_ESTADO_TURNO,
    AUM_HR_INICIO,
    AUM_HR_FIN,
    AUM_ESTADO,
    AUM_USUARIO,
    AUM_CAMBIOS,
    AUM_ACCION,
    AEM_ID,
    AME_ID,
    APM_ID,
    ATU_ID,
    ADM_ID
    ) VALUES (
    :OLD.ADM_OBSERVACIONES,
    :OLD.ADM_FECHA,
    :OLD.ADM_ESTADO_TURNO,
    :OLD.ADM_HR_INICIO,
    :OLD.ADM_HR_FIN,
    :OLD.ADM_ESTADO,
    v_usuario,
    v_cambios,
    v_accion,
    :OLD.AEM_ID,
    :OLD.AME_ID,
    :OLD.APM_ID,
    :OLD.ATU_ID,
    :OLD.ADM_ID
    );
END IF;

EXCEPTION
WHEN OTHERS THEN
    -- No fallar la operación principal por error en auditoría
    DBMS_OUTPUT.PUT_LINE('Error en auditoría: ' || SQLERRM);
END;
/
