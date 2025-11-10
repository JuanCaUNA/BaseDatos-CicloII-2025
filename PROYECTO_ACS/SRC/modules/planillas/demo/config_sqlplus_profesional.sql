/*******************************************************************************
 * CONFIGURACIÓN PROFESIONAL DE SQL*Plus PARA DEMOSTRACIONES
 * 
 * Este script configura el entorno SQL*Plus para que las salidas sean
 * visualmente impactantes y profesionales durante la defensa del proyecto.
 * 
 * MODO DE USO:
 * 1. Ejecutar al iniciar SQL*Plus:
 *    SQL> @SRC/modules/planillas/demo/config_sqlplus_profesional.sql
 * 
 * 2. Luego ejecutar el script de demostración:
 *    SQL> @SRC/modules/planillas/demo/demo_defensa_profesor.sql
 ******************************************************************************/

-- ============================================================================
-- CONFIGURACIÓN BÁSICA DE SQL*Plus
-- ============================================================================

-- Habilitar salidas de DBMS_OUTPUT (CRÍTICO)
SET SERVEROUTPUT ON SIZE UNLIMITED

-- Configurar ancho de línea para que no se corten las salidas
SET LINESIZE 200

-- Configurar cantidad de líneas por página (evita paginación molesta)
SET PAGESIZE 1000

-- Mostrar cantidad de filas afectadas por comandos
SET FEEDBACK ON

-- No mostrar la sustitución de variables (evita ruido visual)
SET VERIFY OFF

-- No hacer eco de comandos ejecutados
SET ECHO OFF

-- Mostrar tiempo de ejecución de comandos (útil para demostrar performance)
SET TIMING OFF

-- Formato de números con separadores de miles
SET NUMFORMAT 999,999,999.99

-- ============================================================================
-- CONFIGURACIÓN DE FORMATO DE COLUMNAS
-- ============================================================================

-- Configurar anchos para columnas comunes en reportes

-- Para nombres de personas
COLUMN nombre FORMAT A50 HEADING "Nombre Completo"
COLUMN nombre_completo FORMAT A50 HEADING "Nombre Completo"
COLUMN empleado FORMAT A40 HEADING "Empleado"

-- Para tipos y descripciones
COLUMN tipo FORMAT A20 HEADING "Tipo"
COLUMN descripcion FORMAT A60 HEADING "Descripción"
COLUMN detalle FORMAT A70 HEADING "Detalle"
COLUMN movimiento FORMAT A25 HEADING "Tipo de Movimiento"
COLUMN codigo FORMAT A15 HEADING "Código"

-- Para fechas
COLUMN fecha FORMAT A20 HEADING "Fecha"
COLUMN fecha_creacion FORMAT A20 HEADING "Fecha Creación"
COLUMN fecha_actualizacion FORMAT A20 HEADING "Fecha Actualización"

-- Para montos (formato costarricense con ₡)
COLUMN monto FORMAT 999,999,990.99 HEADING "Monto"
COLUMN salario FORMAT 999,999,990.99 HEADING "Salario"
COLUMN bruto FORMAT 999,999,990.99 HEADING "Bruto"
COLUMN deducciones FORMAT 999,999,990.99 HEADING "Deducciones"
COLUMN neto FORMAT 999,999,990.99 HEADING "Neto"
COLUMN total FORMAT 999,999,990.99 HEADING "Total"

-- Para porcentajes
COLUMN porcentaje FORMAT 990.99 HEADING "Porcentaje %"
COLUMN tasa FORMAT 990.99 HEADING "Tasa %"

-- Para estados y validaciones
COLUMN estado FORMAT A15 HEADING "Estado"
COLUMN validacion FORMAT A20 HEADING "Validación"
COLUMN resultado FORMAT A30 HEADING "Resultado"

-- Para IDs
COLUMN id FORMAT 9999999 HEADING "ID"
COLUMN planilla_id FORMAT 9999999 HEADING "ID Planilla"
COLUMN detalle_id FORMAT 9999999 HEADING "ID Detalle"

-- Para contadores
COLUMN cantidad FORMAT 99,999 HEADING "Cantidad"
COLUMN total_registros FORMAT 99,999 HEADING "Total Registros"

-- ============================================================================
-- CONFIGURACIÓN DE BREAKS Y COMPUTES (para subtotales)
-- ============================================================================

-- Configurar para que no repita valores en columnas agrupadas
SET BREAK ON REPORT

-- Configurar para mostrar totales al final de reportes
COMPUTE SUM OF monto ON REPORT
COMPUTE SUM OF bruto ON REPORT
COMPUTE SUM OF deducciones ON REPORT
COMPUTE SUM OF neto ON REPORT

-- ============================================================================
-- CONFIGURACIÓN DE MENSAJES DEL SISTEMA
-- ============================================================================

-- Configurar formato de errores SQL
SET SQLTERMINATOR ;
SET SQLBLANKLINES ON

-- Configurar para que no haga pausa automática
SET PAUSE OFF

-- Configurar para que no pregunte al hacer DESCRIBE
SET DESCRIBE DEPTH 1

-- ============================================================================
-- CONFIGURACIÓN DE FORMATO DE FECHA (Costa Rica)
-- ============================================================================

-- Establecer formato de fecha en español
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';
ALTER SESSION SET NLS_DATE_LANGUAGE = 'SPANISH';
ALTER SESSION SET NLS_TERRITORY = 'COSTA RICA';
ALTER SESSION SET NLS_CURRENCY = '₡';

-- ============================================================================
-- CONFIRMACIÓN VISUAL
-- ============================================================================

PROMPT 
PROMPT ╔════════════════════════════════════════════════════════════════════════════╗
PROMPT ║                                                                            ║
PROMPT ║              CONFIGURACIÓN PROFESIONAL DE SQL*Plus CARGADA                ║
PROMPT ║                                                                            ║
PROMPT ╚════════════════════════════════════════════════════════════════════════════╝
PROMPT 
PROMPT   ✓ SERVEROUTPUT habilitado (SIZE UNLIMITED)
PROMPT   ✓ LINESIZE configurado a 200 caracteres
PROMPT   ✓ PAGESIZE configurado a 1000 líneas
PROMPT   ✓ Formato de números con separadores de miles
PROMPT   ✓ Formato de columnas optimizado para reportes
PROMPT   ✓ Formato de fecha en español (Costa Rica)
PROMPT   ✓ Símbolo de moneda: ₡ (Colón costarricense)
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT   Su entorno SQL*Plus está listo para demostraciones profesionales
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT   Siguiente paso:
PROMPT   SQL> @SRC/modules/planillas/demo/demo_defensa_profesor.sql
PROMPT 
PROMPT ════════════════════════════════════════════════════════════════════════════
PROMPT 

-- ============================================================================
-- DEFINIR VARIABLES DE SUSTITUCIÓN COMUNES
-- ============================================================================

-- Definir mes y año de prueba (puede cambiarse fácilmente)
DEFINE test_mes = 11
DEFINE test_anio = 2025

PROMPT   Variables definidas:
PROMPT     &test_mes  = Mes de prueba
PROMPT     &test_anio = Año de prueba
PROMPT 
PROMPT ╔════════════════════════════════════════════════════════════════════════════╗
PROMPT ║  ¡Listo para impresionar al profesor! 🎓                                  ║
PROMPT ╚════════════════════════════════════════════════════════════════════════════╝
PROMPT
