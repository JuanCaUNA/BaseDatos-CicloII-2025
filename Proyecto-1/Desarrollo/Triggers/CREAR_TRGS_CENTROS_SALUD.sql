CREATE OR REPLACE TRIGGER TRG_HIST_PROCEDIMIENTO
AFTER UPDATE OF APD_COSTO, APD_PAGO, APD_ESTADO ON ACS_PROCEDIMIENTO
FOR EACH ROW
DECLARE
    -- Helpers para comparaciones NULL-safe
    FUNCTION num_changed(o NUMBER, n NUMBER) RETURN BOOLEAN IS
    BEGIN
        IF o IS NULL AND n IS NULL THEN
            RETURN FALSE;
        ELSIF o IS NULL AND n IS NOT NULL THEN
            RETURN TRUE;
        ELSIF o IS NOT NULL AND n IS NULL THEN
            RETURN TRUE;
        ELSE
            RETURN (o != n);
        END IF;
    END;

    FUNCTION str_changed(o VARCHAR2, n VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        IF o IS NULL AND n IS NULL THEN
            RETURN FALSE;
        ELSIF o IS NULL AND n IS NOT NULL THEN
            RETURN TRUE;
        ELSIF o IS NOT NULL AND n IS NULL THEN
            RETURN TRUE;
        ELSE
            RETURN NOT (o = n);
        END IF;
    END;
BEGIN
    -- Solo actúa si hubo cambio real en costo, pago o estado
    IF num_changed(:OLD.APD_COSTO, :NEW.APD_COSTO)
       OR num_changed(:OLD.APD_PAGO,  :NEW.APD_PAGO)
       OR str_changed(:OLD.APD_ESTADO, :NEW.APD_ESTADO) THEN

        -- Cierra historial abierto (si existe)
        UPDATE ACS_HISTORIAL_PROCEDIMIENTO h
        SET h.AHP_FECHA_FIN = SYSTIMESTAMP
        WHERE h.APD_ID = :OLD.APD_ID
          AND h.AHP_FECHA_FIN IS NULL
          AND EXISTS (
              SELECT 1
              FROM ACS_HISTORIAL_PROCEDIMIENTO hh
              WHERE hh.APD_ID = :OLD.APD_ID
                AND hh.AHP_FECHA_FIN IS NULL
          );

        -- Inserta nuevo registro de historial
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
        -- Fallar claramente para evitar inconsistencia silenciosa
        RAISE_APPLICATION_ERROR(-20030, 'TRG_HIST_PROCEDIMIENTO error: ' || SQLERRM);
END;
/

CREATE OR REPLACE TRIGGER TRG_PROC_APLICADO_VALID
BEFORE INSERT OR UPDATE ON ACS_PROC_APLICADO
FOR EACH ROW
DECLARE
    v_costo NUMBER;
    v_pago  NUMBER;
BEGIN
    -- Obtiene los valores de costo y pago solo si es un INSERT
    IF INSERTING THEN
        BEGIN
            SELECT APD_COSTO, APD_PAGO
            INTO v_costo, v_pago
            FROM ACS_PROCEDIMIENTO
            WHERE APD_ID = :NEW.APD_ID;

            -- Asigna los valores por defecto si son NULL
            :NEW.APA_COSTO := COALESCE(:NEW.APA_COSTO, v_costo);
            :NEW.APA_PAGO := COALESCE(:NEW.APA_PAGO, v_pago);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20020, 'Procedimiento no encontrado.');
        END;
    END IF;

    -- Validaciones obligatorias
    IF :NEW.APA_COSTO IS NULL OR :NEW.APA_COSTO < 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'El costo aplicado no puede ser nulo ni negativo.');
    END IF;

    IF :NEW.APA_PAGO IS NULL OR :NEW.APA_PAGO < 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'El pago al médico no puede ser nulo ni negativo.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_UPDATE_ESTADO_ESCALA
FOR UPDATE OF ADM_ESTADO_TURNO ON ACS_DETALLE_MENSUAL
COMPOUND TRIGGER

  TYPE t_num_tab IS TABLE OF NUMBER;
  g_aem_ids t_num_tab := t_num_tab();

  /* BEFORE STATEMENT (opcional) */
  BEFORE STATEMENT IS
  BEGIN
    NULL;
  END BEFORE STATEMENT;

  /* AFTER EACH ROW: recolecta AEM_IDs únicos afectados */
  AFTER EACH ROW IS
    l_found BOOLEAN;
  BEGIN
    IF :NEW.AEM_ID IS NOT NULL THEN
      l_found := FALSE;
      FOR i IN 1 .. g_aem_ids.COUNT LOOP
        IF g_aem_ids(i) = :NEW.AEM_ID THEN
          l_found := TRUE;
          EXIT;
        END IF;
      END LOOP;

      IF NOT l_found THEN
        g_aem_ids.EXTEND;
        g_aem_ids(g_aem_ids.COUNT) := :NEW.AEM_ID;
      END IF;
    END IF;
  END AFTER EACH ROW;

  /* AFTER STATEMENT: procesa cada AEM_ID único (evita mutating table) */
  AFTER STATEMENT IS
    v_total    NUMBER;
    v_completo NUMBER;
  BEGIN
    FOR idx IN 1 .. g_aem_ids.COUNT LOOP
      BEGIN
        SELECT COUNT(*),
               NVL(SUM(CASE WHEN NVL(ADM_ESTADO_TURNO,'') IN ('CUMPLIDO','REEMPLAZADO') THEN 1 ELSE 0 END), 0)
        INTO v_total, v_completo
        FROM ACS_DETALLE_MENSUAL
        WHERE AEM_ID = g_aem_ids(idx);

        IF v_total > 0 AND v_total = v_completo THEN
          -- Actualiza solo si realmente cambia el estado
          UPDATE ACS_ESCALA_MENSUAL
          SET AEM_ESTADO = 'LISTA PARA PAGO'
          WHERE AEM_ID = g_aem_ids(idx)
            AND NVL(AEM_ESTADO,'') <> 'LISTA PARA PAGO';
        END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL; -- no debería pasar
        WHEN OTHERS THEN
          -- Log simple; no queremos dejar que la auditoría bloquee la operación
          DBMS_OUTPUT.PUT_LINE('TRG_UPDATE_ESTADO_ESCALA error para AEM_ID=' || g_aem_ids(idx) || ': ' || SQLERRM);
      END;
    END LOOP;

    -- limpia la colección (buena práctica)
    g_aem_ids.DELETE;
  END AFTER STATEMENT;

END TRG_UPDATE_ESTADO_ESCALA;
/

CREATE OR REPLACE TRIGGER TRG_AUDIT_DETALLE_MENSUAL
AFTER INSERT OR UPDATE OR DELETE ON ACS_DETALLE_MENSUAL
FOR EACH ROW
DECLARE
    v_cambios VARCHAR2(1000);
    
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF INSERTING THEN
        v_cambios := 'INSERT';
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
            v_cambios,
            :NEW.AEM_ID,
            :NEW.AME_ID,
            :NEW.APM_ID,
            :NEW.ATU_ID,
            :NEW.ADM_ID
        );

    ELSIF UPDATING THEN
        v_cambios := '';
        
        IF NVL(:OLD.ADM_OBSERVACIONES,'') != NVL(:NEW.ADM_OBSERVACIONES,'') THEN
            v_cambios := v_cambios || 'ADM_OBSERVACIONES,';
        END IF;
        IF NVL(:OLD.ADM_ESTADO_TURNO,'') != NVL(:NEW.ADM_ESTADO_TURNO,'') THEN
            v_cambios := v_cambios || 'ADM_ESTADO_TURNO,';
        END IF;
        IF NVL(:OLD.ADM_HR_INICIO,SYSTIMESTAMP) != NVL(:NEW.ADM_HR_INICIO,SYSTIMESTAMP) THEN
            v_cambios := v_cambios || 'ADM_HR_INICIO,';
        END IF;
        IF NVL(:OLD.ADM_HR_FIN,SYSTIMESTAMP) != NVL(:NEW.ADM_HR_FIN,SYSTIMESTAMP) THEN
            v_cambios := v_cambios || 'ADM_HR_FIN,';
        END IF;
        IF NVL(:OLD.ADM_ESTADO,'') != NVL(:NEW.ADM_ESTADO,'') THEN
            v_cambios := v_cambios || 'ADM_ESTADO,';
        END IF;
        IF NVL(:OLD.AEM_ID,0) != NVL(:NEW.AEM_ID,0) THEN
            v_cambios := v_cambios || 'AEM_ID,';
        END IF;
        IF NVL(:OLD.AME_ID,0) != NVL(:NEW.AME_ID,0) THEN
            v_cambios := v_cambios || 'AME_ID,';
        END IF;
        IF NVL(:OLD.APM_ID,0) != NVL(:NEW.APM_ID,0) THEN
            v_cambios := v_cambios || 'APM_ID,';
        END IF;
        IF NVL(:OLD.ATU_ID,0) != NVL(:NEW.ATU_ID,0) THEN
            v_cambios := v_cambios || 'ATU_ID,';
        END IF;

        -- Solo inserta si hubo cambios
        IF v_cambios IS NOT NULL AND v_cambios != '' THEN
            -- Quita la coma final
            v_cambios := RTRIM(v_cambios,',');

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
                v_cambios,
                :NEW.AEM_ID,
                :NEW.AME_ID,
                :NEW.APM_ID,
                :NEW.ATU_ID,
                :NEW.ADM_ID
            );
        END IF;

    ELSIF DELETING THEN
        v_cambios := 'DELETE';
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
            v_cambios,
            :OLD.AEM_ID,
            :OLD.AME_ID,
            :OLD.APM_ID,
            :OLD.ATU_ID,
            :OLD.ADM_ID
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- No bloquea la operación principal
        DBMS_OUTPUT.PUT_LINE('Error en auditoría detalle mensual: ' || SQLERRM);
        NULL;
END;
/