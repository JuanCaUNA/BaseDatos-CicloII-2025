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
