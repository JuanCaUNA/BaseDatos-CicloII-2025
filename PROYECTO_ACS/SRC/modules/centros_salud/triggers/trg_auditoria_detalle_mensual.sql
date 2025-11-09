-- =============================================
-- Trigger: TRG_AUDITORIA_DETALLE_MENSUAL
-- Audita INSERT, UPDATE, DELETE en ACS_DETALLE_MENSUAL
-- Registra cambios en ACS_AUDITORIA_DETALLE_MENSUAL
-- Fecha: 2025-11-09
-- =============================================
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
