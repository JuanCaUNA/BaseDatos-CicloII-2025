-- =============================================================
-- TEST INTEGRAL - MÓDULO PLANILLAS (MÉDICOS Y ADMINISTRATIVOS)
-- Autor: [Tu nombre]
-- Fecha: [2025-11-03]
-- Descripción:
--   Limpia datos previos, crea datos base, ejecuta procedimientos
--   PRC_Generar_Planillas_Medicos y PRC_Generar_Planillas_Admin,
--   y muestra resultados.
-- =============================================================

SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT 🔹 INICIO DE PRUEBAS - MÓDULO PLANILLAS
PROMPT ============================================================

-- =============================================================
-- 1️⃣ LIMPIEZA DE TABLAS
-- =============================================================
PROMPT → Limpiando tablas previas...

DELETE FROM ACS_MOVIMIENTO_PLANILLA;
DELETE FROM ACS_DETALLE_PLANILLA;
DELETE FROM ACS_PLANILLA;
DELETE FROM ACS_PERSONAL_TIPO_PLANILLA;
DELETE FROM ACS_TIPO_PLANILLA;
DELETE FROM ACS_USUARIO;
DELETE FROM ACS_PERSONA;
COMMIT;

PROMPT Tablas limpiadas correctamente.

-- =============================================================
-- 2️⃣ CREACIÓN DE DATOS BASE
-- =============================================================

PROMPT → Insertando tipos de planilla base...

INSERT INTO ACS_TIPO_PLANILLA (ATP_NOMBRE, ATP_APLICA_A, ATP_DESC, ATP_ESTADO, ATP_DESCRIPCION)
VALUES ('Planilla Médicos', 'MEDICO', 'Planilla mensual para médicos', 'ACTIVO', 'Incluye médicos activos');

INSERT INTO ACS_TIPO_PLANILLA (ATP_NOMBRE, ATP_APLICA_A, ATP_DESC, ATP_ESTADO, ATP_DESCRIPCION)
VALUES ('Planilla Administrativos', 'ADMINISTRATIVO', 'Planilla mensual para administrativos', 'ACTIVO', 'Incluye personal administrativo');

COMMIT;

PROMPT → Insertando personas base...

INSERT INTO ACS_PERSONA (APE_CEDULA, APE_NOMBRE, APE_P_APELLIDO, APE_FECHA_NACIMIENTO,
                         APE_TIPO_USUARIO, APE_ESTADO_REGISTRO, APE_EMAIL, APE_FECHA_ACTUALIZACION)
VALUES ('101010101', 'Carlos', 'Mora', SYSDATE, 'MEDICO', 'APROBADO', 'carlos@una.cr', SYSTIMESTAMP);

INSERT INTO ACS_PERSONA (APE_CEDULA, APE_NOMBRE, APE_P_APELLIDO, APE_FECHA_NACIMIENTO,
                         APE_TIPO_USUARIO, APE_ESTADO_REGISTRO, APE_EMAIL, APE_FECHA_ACTUALIZACION)
VALUES ('202020202', 'Rosa', 'Vega', SYSDATE, 'ADMINISTRATIVO', 'APROBADO', 'rosa@una.cr', SYSTIMESTAMP);

COMMIT;

PROMPT → Insertando usuarios base...

INSERT INTO ACS_USUARIO (APE_ID, AUS_ESTADO, AUS_FECHA_CREACION, AUS_ULTIMO_ACCESO)
VALUES ((SELECT APE_ID FROM ACS_PERSONA WHERE APE_CEDULA = '101010101'), 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP);

INSERT INTO ACS_USUARIO (APE_ID, AUS_ESTADO, AUS_FECHA_CREACION, AUS_ULTIMO_ACCESO)
VALUES ((SELECT APE_ID FROM ACS_PERSONA WHERE APE_CEDULA = '202020202'), 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP);

COMMIT;

PROMPT → Asociando usuarios a tipos de planilla...

DECLARE
  v_med_aus NUMBER;
  v_admin_aus NUMBER;
  v_med_tipo NUMBER;
  v_admin_tipo NUMBER;
BEGIN
  SELECT AUS_ID INTO v_med_aus FROM ACS_USUARIO WHERE APE_ID = (SELECT APE_ID FROM ACS_PERSONA WHERE APE_CEDULA='101010101');
  SELECT AUS_ID INTO v_admin_aus FROM ACS_USUARIO WHERE APE_ID = (SELECT APE_ID FROM ACS_PERSONA WHERE APE_CEDULA='202020202');
  SELECT ATP_ID INTO v_med_tipo FROM ACS_TIPO_PLANILLA WHERE ATP_APLICA_A='MEDICO';
  SELECT ATP_ID INTO v_admin_tipo FROM ACS_TIPO_PLANILLA WHERE ATP_APLICA_A='ADMINISTRATIVO';

  INSERT INTO ACS_PERSONAL_TIPO_PLANILLA (APTP_ACTIVO, APTP_FECHA_ASIGNACION, AUS_ID, ATP_ID)
  VALUES (1, SYSTIMESTAMP, v_med_aus, v_med_tipo);

  INSERT INTO ACS_PERSONAL_TIPO_PLANILLA (APTP_ACTIVO, APTP_FECHA_ASIGNACION, AUS_ID, ATP_ID)
  VALUES (1, SYSTIMESTAMP, v_admin_aus, v_admin_tipo);

  COMMIT;
END;
/

PROMPT Datos base creados correctamente.

-- =============================================================
-- 3️⃣ EJECUCIÓN DE PROCEDIMIENTOS
-- =============================================================
PROMPT → Ejecutando generación de planillas...

BEGIN
  PRC_Generar_Planillas_Medicos(11, 2025);
  PRC_Generar_Planillas_Admin(11, 2025);
END;
/

PROMPT → Planillas generadas. Consultando resultados...

-- =============================================================
-- 4️⃣ CONSULTAS DE VALIDACIÓN
-- =============================================================

PROMPT → Planillas generadas:
SELECT APL_ID, ATP_ID, APL_ESTADO, APL_TOT_BRUTO, APL_TOT_DED, APL_TOT_NETO FROM ACS_PLANILLA;

PROMPT → Detalles de planillas:
SELECT APL_ID, ADP_TIPO_PERSONA, ADP_SALARIO_BASE, ADP_DED, APD_NETO FROM ACS_DETALLE_PLANILLA;

PROMPT → Asociación de usuarios:
SELECT * FROM ACS_PERSONAL_TIPO_PLANILLA;

-- =============================================================
-- 5️⃣ LIMPIEZA FINAL (opcional)
-- =============================================================
PROMPT → Eliminando registros de prueba...

DELETE FROM ACS_MOVIMIENTO_PLANILLA;
DELETE FROM ACS_DETALLE_PLANILLA;
DELETE FROM ACS_PLANILLA;
DELETE FROM ACS_PERSONAL_TIPO_PLANILLA;
DELETE FROM ACS_TIPO_PLANILLA;
DELETE FROM ACS_USUARIO;
DELETE FROM ACS_PERSONA;
COMMIT;

PROMPT ============================================================
PROMPT ✅ PRUEBAS COMPLETADAS CORRECTAMENTE
PROMPT ============================================================
