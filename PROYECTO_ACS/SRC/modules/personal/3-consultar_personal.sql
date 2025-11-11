-- ============================================================================
-- CONSULTAS PARA MODULO DE PERSONAL
-- Archivo: consultar.sql
-- Descripción: Consultas para todas las tablas del módulo de personal
-- Fecha: 9 de noviembre de 2025
-- ============================================================================

-- ============================================================================
-- 1. CONSULTA ACS_BANCO
-- ============================================================================
-- Consulta básica de todos los bancos
SELECT *
FROM ACS_BANCO
ORDER BY ABA_NOMBRE;

-- ============================================================================
-- 2. CONSULTA ACS_PERSONA
-- ============================================================================
-- Consulta básica de todas las personas
SELECT *
FROM ACS_PERSONA
ORDER BY APE_FECHA_CREACION DESC;

-- ============================================================================
-- 3. CONSULTA ACS_USUARIO
-- ============================================================================
-- Consulta básica de todos los usuarios
SELECT 
    U.AUS_ID,
    U.AUS_ESTADO,
    U.AUS_FECHA_CREACION,
    U.AUS_ULTIMO_ACCESO,
    P.APE_CEDULA,
    P.APE_NOMBRE || ' ' || P.APE_P_APELLIDO || ' ' || NVL(P.APE_S_APELLIDO, '') AS NOMBRE_COMPLETO,
    P.APE_EMAIL,
    P.APE_TIPO_USUARIO
FROM ACS_USUARIO U
INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
ORDER BY U.AUS_FECHA_CREACION DESC;

-- ============================================================================
-- 4. CONSULTA ACS_CUENTA_BANCARIA
-- ============================================================================
-- Consulta básica de todas las cuentas bancarias
SELECT 
    CB.ACB_ID,
    CB.ACB_NUMERO_CUENTA,
    CB.ACB_ES_PRINCIPAL,
    CB.ACB_TIPO_CUENTA,
    CB.ACB_ESTADO,
    P.APE_CEDULA,
    P.APE_NOMBRE || ' ' || P.APE_P_APELLIDO AS NOMBRE_USUARIO,
    B.ABA_NOMBRE AS NOMBRE_BANCO
FROM ACS_CUENTA_BANCARIA CB
INNER JOIN ACS_USUARIO U ON CB.AUS_ID = U.AUS_ID
INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
INNER JOIN ACS_BANCO B ON CB.ABA_ID = B.ABA_ID
ORDER BY P.APE_NOMBRE, CB.ACB_ES_PRINCIPAL DESC;

-- ============================================================================
-- 5. CONSULTA ACS_TIPO_DOCUMENTO
-- ============================================================================
-- Consulta básica de todos los tipos de documento
SELECT *
FROM ACS_TIPO_DOCUMENTO
ORDER BY ATD_TIPO_USUARIO, ATD_DOCUMENTO_REQUERIDO;

-- ============================================================================
-- 6. CONSULTA ACS_DOCUMENTO_USUARIO
-- ============================================================================
-- Consulta básica de todos los documentos de usuario
SELECT 
    DU.ADU_ID,
    P.APE_CEDULA,
    P.APE_NOMBRE || ' ' || P.APE_P_APELLIDO AS NOMBRE_USUARIO,
    TD.ATD_DOCUMENTO_REQUERIDO,
    DU.ADU_URL,
    DU.ADU_COMENTARIOS,
    DU.ADU_ESTADO,
    DU.ADU_FECHA_CREACION,
    DU.ADU_FECHA_ACTUALIZACION
FROM ACS_DOCUMENTO_USUARIO DU
INNER JOIN ACS_USUARIO U ON DU.AUS_ID = U.AUS_ID
INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
INNER JOIN ACS_TIPO_DOCUMENTO TD ON DU.ATD_ID = TD.ATD_ID
ORDER BY DU.ADU_FECHA_CREACION DESC;

-- ============================================================================
-- 7. CONSULTA ACS_PERFIL
-- ============================================================================
-- Consulta básica de todos los perfiles
SELECT 
    APF_ID,
    TRIM(APF_NOMBRE) AS NOMBRE,
    TRIM(APF_DESCRIPCION) AS DESCRIPCION,
    APF_PADRE_ID
FROM ACS_PERFIL
ORDER BY APF_NOMBRE;

-- ============================================================================
-- 8. CONSULTA ACS_PERMISO
-- ============================================================================
-- Consulta básica de todos los permisos
SELECT *
FROM ACS_PERMISO
ORDER BY APR_PANTALLA;

-- ============================================================================
-- 9. CONSULTA ACS_PERFIL_PERMISO
-- ============================================================================
-- Consulta básica de relación perfil-permiso
SELECT 
    TRIM(PF.APF_NOMBRE) AS PERFIL,
    PM.APR_PANTALLA,
    CASE WHEN PM.APR_LEER = 1 THEN '-L' ELSE '-' END ||
    CASE WHEN PM.APR_CREAR = 1 THEN '-C' ELSE '-' END ||
    CASE WHEN PM.APR_EDITAR = 1 THEN '-E' ELSE '-' END ||
    CASE WHEN PM.APR_BORRAR = 1 THEN '-B' ELSE '-' END AS PERMISOS_CRUD
FROM ACS_PERFIL_PERMISO PP
INNER JOIN ACS_PERFIL PF ON PP.APF_ID = PF.APF_ID
INNER JOIN ACS_PERMISO PM ON PP.APR_ID = PM.APR_ID
ORDER BY PF.APF_NOMBRE, PM.APR_PANTALLA;

-- ============================================================================
-- 10. CONSULTA ACS_USUARIO_PERFIL
-- ============================================================================
-- Consulta básica de relación usuario-perfil
SELECT 
    U.AUS_ID,
    P.APE_CEDULA,
    P.APE_NOMBRE || ' ' || P.APE_P_APELLIDO AS NOMBRE_USUARIO,
    TRIM(PF.APF_NOMBRE) AS PERFIL
FROM ACS_USUARIO_PERFIL UP
INNER JOIN ACS_USUARIO U ON UP.AUS_ID = U.AUS_ID
INNER JOIN ACS_PERSONA P ON U.APE_ID = P.APE_ID
INNER JOIN ACS_PERFIL PF ON UP.APF_ID = PF.APF_ID
ORDER BY P.APE_NOMBRE, PF.APF_NOMBRE;

-- ============================================================================
-- FIN DEL ARCHIVO
-- ============================================================================
