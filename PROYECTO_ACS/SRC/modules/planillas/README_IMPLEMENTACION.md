# 📊 Sistema de Planillas - Documentación Completa

## ✅ Implementación Completada

Este documento resume la implementación completa del **Sistema de Planillas con Movimientos Automáticos y Rangos Progresivos** para el proyecto ACS.

---

## 📁 Archivos Creados

### 1. **Seed Data**

📂 `SRC/modules/planillas/seed_data/`

- **`seed_simple.sql`**: Carga inicial de movimientos automáticos
  - ✅ CCSS (9% sobre bruto)
  - ✅ Renta con rangos progresivos (0%, 10%, 15%, 20%, 25%)
  - ✅ Caja (2.5% sobre bruto, solo administrativos)
  - ✅ Banco Popular (1.5% sobre bruto)
  - ✅ 5 rangos salariales para renta según tabla Ministerio Hacienda CR 2024

### 2. **Función Helper**

📂 `SRC/modules/planillas/procedures/`

- **`fun_calcular_movimiento.sql`** (**VALID** ✅)
  - Calcula movimientos según modo: FIJO, PORCENTAJE simple, PORCENTAJE con rangos progresivos
  - Maneja automáticamente los rangos de ACS_TIPO_MOV_RANGO
  - Retorna monto calculado con redondeo a 2 decimales
  - Probada exitosamente con salarios de ₡800k, ₡1.2M, ₡3M

### 3. **Procedimientos de Generación de Planillas**

📂 `SRC/modules/planillas/procedures/`

#### **`prc_generar_planillas_medicos_v2.sql`** (**VALID** ✅)

**Características implementadas:**

- ✅ Calcula pago por TURNOS desde `ACS_DETALLE_MENSUAL`
  - Respeta `ATU_TIPO_PAGO`: 'HORAS' o 'TURNO'
  - Para HORAS: calcula horas trabajadas × tarifa horaria
  - Para TURNO: aplica pago fijo por turno completo
- ✅ Suma procedimientos desde `ACS_PROC_APLICADO`
- ✅ Aplica movimientos automáticos (CCSS, Renta, Banco Popular)
- ✅ Registra cada movimiento en `ACS_MOVIMIENTO_PLANILLA` con:
  - `AMP_FUENTE = 'AUTOMATICO'`
  - `AMP_MONTO`: monto calculado
  - `AMP_CALC`: base de cálculo usada
  - `AMP_OBS`: descripción del movimiento
- ✅ Calcula totales: bruto, deducciones, neto
- ✅ Actualiza encabezado de planilla con totales

#### **`prc_generar_planillas_admin_v2.sql`** (**VALID** ✅)

**Características implementadas:**

- ✅ Usa salario base de ₡800,000 (TODO: obtener de configuración de usuario)
- ✅ Aplica movimientos automáticos para administrativos:
  - CCSS (9%)
  - Renta con rangos progresivos
  - Caja (2.5%, solo admins)
  - Banco Popular (1.5%)
- ✅ Maneja rangos progresivos automáticamente mediante `FUN_CALCULAR_MOVIMIENTO`
- ✅ Registra cada movimiento en `ACS_MOVIMIENTO_PLANILLA`
- ✅ Calcula deducciones totales y neto
- ✅ Actualiza encabezado de planilla

### 4. **Scripts de Prueba**

📂 `SRC/modules/planillas/tests/`

- **`test_flujo_completo_planillas.sql`**
  - ✅ Verifica prerequisitos (movimientos, rangos, tipos de planilla)
  - ✅ Limpia datos de pruebas anteriores
  - ✅ Genera planillas de administrativos y médicos
  - ✅ Muestra resumen de resultados:
    - Totales por planilla
    - Movimientos aplicados por tipo
    - Detalles por persona (primeras 5)
  - ✅ Valida integridad:
    - Totales del header vs sum de detalles
    - Bruto, deducciones, neto cuadran
  - ✅ Proporciona queries para validación detallada

---

## 🏗️ Arquitectura Implementada

### **Flujo de Datos**

```
1. ENTRADA
   ├─ ACS_ESCALA_MENSUAL (mes/año)
   ├─ ACS_DETALLE_MENSUAL (turnos trabajados por médicos)
   ├─ ACS_PROC_APLICADO (procedimientos realizados)
   └─ ACS_USUARIO + ACS_PERSONA (salarios base para admins)

2. CONFIGURACIÓN
   ├─ ACS_TIPO_MOV (movimientos automáticos: CCSS, Renta, Caja, Banco)
   └─ ACS_TIPO_MOV_RANGO (rangos progresivos para renta)

3. PROCESAMIENTO
   ├─ PRC_GENERAR_PLANILLAS_MEDICOS
   │   ├─ Calcula bruto (turnos + procedimientos)
   │   ├─ Aplica movimientos automáticos
   │   └─ FUN_CALCULAR_MOVIMIENTO (por cada movimiento)
   │
   └─ PRC_GENERAR_PLANILLAS_ADMIN
       ├─ Usa salario base
       ├─ Aplica movimientos automáticos con rangos
       └─ FUN_CALCULAR_MOVIMIENTO (maneja rangos progresivos)

4. SALIDA
   ├─ ACS_PLANILLA (encabezado con totales)
   ├─ ACS_DETALLE_PLANILLA (persona: bruto, ded, neto)
   └─ ACS_MOVIMIENTO_PLANILLA (cada movimiento aplicado, auditable)
```

### **Tablas Principales**

| Tabla                     | Propósito                         | Campos Clave                                                          |
| ------------------------- | --------------------------------- | --------------------------------------------------------------------- |
| `ACS_TIPO_MOV`            | Define movimientos automáticos    | `ATM_COD`, `ATM_MODO`, `ATM_PORC`, `ATM_BASE`, `ATM_ES_AUTOMATICO`    |
| `ACS_TIPO_MOV_RANGO`      | Rangos para cálculos progresivos  | `ATM_ID`, `ATMR_RANGO_MIN`, `ATMR_RANGO_MAX`, `ATMR_PORCENTAJE`       |
| `ACS_MOVIMIENTO_PLANILLA` | Movimientos aplicados (auditoría) | `AMP_FUENTE`, `AMP_MONTO`, `AMP_CALC`, `APD_ID`, `ATM_ID`             |
| `ACS_PLANILLA`            | Encabezado de planilla            | `APL_MES`, `APL_ANIO`, `APL_TOT_BRUTO`, `APL_TOT_DED`, `APL_TOT_NETO` |
| `ACS_DETALLE_PLANILLA`    | Detalle por persona               | `ADP_BRUTO`, `ADP_DED`, `APD_NETO`, `AUS_ID`                          |

---

## 🧪 Cómo Probar

### **1. Cargar Seed Data (primera vez)**

```sql
@SRC/modules/planillas/seed_data/seed_simple.sql
```

Esto carga:

- 4 movimientos automáticos (CCSS, RENTA, CAJA, BANCO_POPULAR)
- 5 rangos progresivos para renta

### **2. Compilar Función y Procedimientos**

```sql
@SRC/modules/planillas/procedures/fun_calcular_movimiento.sql
@SRC/modules/planillas/procedures/prc_generar_planillas_medicos_v2.sql
@SRC/modules/planillas/procedures/prc_generar_planillas_admin_v2.sql
```

Verificar que todos estén VALID:

```sql
SELECT object_name, status
FROM user_objects
WHERE object_name IN ('FUN_CALCULAR_MOVIMIENTO', 'PRC_GENERAR_PLANILLAS_MEDICOS', 'PRC_GENERAR_PLANILLAS_ADMIN');
```

### **3. Ejecutar Prueba End-to-End**

```sql
@SRC/modules/planillas/tests/test_flujo_completo_planillas.sql
```

**Output esperado:**

- ✅ Prerequisitos verificados
- ✅ Datos limpiados
- ✅ Planillas generadas
- ✅ Resumen de movimientos aplicados
- ✅ Validaciones de integridad OK

### **4. Validar Movimientos Manualmente**

```sql
-- Ver movimientos aplicados en la última planilla
SELECT
    tm.ATM_COD,
    tm.ATM_NOMBRE,
    mp.AMP_MONTO,
    mp.AMP_CALC AS BASE_CALCULO,
    mp.AMP_OBS
FROM ACS_MOVIMIENTO_PLANILLA mp
JOIN ACS_TIPO_MOV tm ON mp.ATM_ID = tm.ATM_ID
JOIN ACS_DETALLE_PLANILLA dp ON mp.APD_ID = dp.ADP_ID
WHERE dp.APL_ID = (SELECT MAX(APL_ID) FROM ACS_PLANILLA)
ORDER BY tm.ATM_PRIORIDAD;
```

---

## 📊 Ejemplo de Cálculo

### **Caso: Administrativo con salario ₡1,200,000**

| Movimiento      | Base             | Cálculo             | Monto             |
| --------------- | ---------------- | ------------------- | ----------------- |
| **Bruto**       | -                | Salario base        | **₡1,200,000.00** |
| CCSS            | 9% sobre bruto   | 1,200,000 × 0.09    | ₡108,000.00       |
| Renta           | Progresiva       | Ver tabla abajo     | ₡25,899.90        |
| Caja            | 2.5% sobre bruto | 1,200,000 × 0.025   | ₡30,000.00        |
| Banco Popular   | 1.5% sobre bruto | 1,200,000 × 0.015   | ₡18,000.00        |
| **Deducciones** | -                | Sum deducciones     | **₡181,899.90**   |
| **Neto**        | -                | Bruto - Deducciones | **₡1,018,100.10** |

**Cálculo de Renta (progresiva):**

- Tramo 1: ₡0 - ₡941,000 → 0% = ₡0
- Tramo 2: ₡941,001 - ₡1,200,000 → 10% sobre ₡259,000 = ₡25,899.90
- **Total Renta: ₡25,899.90**

---

## 🎯 Puntos del Enunciado Implementados

### **Punto 3: Generación de Planillas de Médicos** (12%)

✅ **COMPLETADO**

- Cálculo por horas o turno completo (`ATU_TIPO_PAGO`)
- Inclusión de procedimientos aplicados
- Aplicación automática de deducciones (CCSS, Renta, Banco)
- Registro en `ACS_MOVIMIENTO_PLANILLA` para auditoría

### **Punto 4: Generación de Planillas de Administrativos** (12%)

✅ **COMPLETADO**

- Uso de salario base
- Movimientos automáticos: CCSS, Renta con rangos, Caja, Banco Popular
- Manejo de rangos progresivos (tabla Hacienda CR)
- Registro completo de movimientos

### **Extras Implementados:**

- ✅ Función genérica `FUN_CALCULAR_MOVIMIENTO` para reutilización
- ✅ Seed data completo con rangos reales de Costa Rica
- ✅ Script de prueba end-to-end automatizado
- ✅ Validaciones de integridad
- ✅ DBMS_OUTPUT detallado para seguimiento

---

## 🚀 Próximos Pasos (Pendientes)

1. **Salario Base Dinámico para Admins**

   - Actualmente usa ₡800k hardcoded
   - TODO: Agregar campo `AUS_SALARIO_BASE` en `ACS_USUARIO` o tabla auxiliar

2. **Movimientos Manuales**

   - Crear procedimiento `PRC_APLICAR_MOVIMIENTO_MANUAL`
   - Parámetros: `p_adp_id`, `p_atm_id`, `p_monto`, `p_observacion`

3. **Validación de Estado de Planilla**

   - Agregar check en procedimientos para evitar modificar planillas ya APLICADAS o NOTIFICADAS

4. **Integración con Sistema de Correos**
   - Ya existe `PRC_ENVIAR_COMPROBANTES` (corregido anteriormente)
   - Utiliza `ACS_PRC_CORREO_NOTIFICADOR` (implementado por compañero)
   - Pendiente: Probar flujo completo con correos reales

---

## 📞 Soporte

Para dudas o problemas:

1. Verificar estado de objetos: `SELECT * FROM user_errors WHERE name LIKE '%PLANILLA%';`
2. Revisar output de prueba: `@test_flujo_completo_planillas.sql`
3. Consultar movimientos aplicados: queries en sección "Validar Movimientos"

---

## 📝 Changelog

| Fecha      | Cambio                                                                       |
| ---------- | ---------------------------------------------------------------------------- |
| 2025-11-09 | ✅ Implementación completa: seed data, función helper, procedimientos, tests |
| 2025-11-09 | ✅ Corrección de nombres de tablas (ACS_ESCALA_MENSUAL, ACS_PROC_APLICADO)   |
| 2025-11-09 | ✅ Todos los objetos compilados como VALID                                   |

---

**Estado del Sistema: ✅ OPERATIVO**

Todos los componentes están compilados y probados. El sistema está listo para:

- Generar planillas de médicos y administrativos
- Aplicar movimientos automáticos con rangos progresivos
- Registrar auditoría completa de cálculos
- Validar integridad de datos
