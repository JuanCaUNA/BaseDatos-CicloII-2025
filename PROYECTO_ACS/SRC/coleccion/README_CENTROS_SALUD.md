# 🏥 Módulo de Centros de Salud - Guía de Carga de Datos

## 📋 Descripción General

Este módulo gestiona la información de centros médicos, turnos, escalas mensuales, procedimientos y su relación con médicos del sistema ACS.

## 🗂️ Estructura de Archivos

### Orden de Ejecución

1. **`5.0-correcciones_schema_centros.sql`** ⚠️ **(EJECUTAR PRIMERO)**
   - Corrige problemas de sintaxis en constraints del schema original
   - Arregla nombres de índices incorrectos
   - Verifica integridad de foreign keys

2. **`5.1-prc_fun_trg_centro-salud.sql`**
   - Procedimientos almacenados para gestión de escalas
   - Triggers de auditoría y validación
   - Funciones auxiliares

3. **`5.2-datos_centro_salud.sql`** ✅ **(GENERADO)**
   - Creación de tablas faltantes (`ACS_MEDICO`, `ACS_DETALLE_MENSUAL`, `ACS_HISTORIAL_PROCEDIMIENTO`)
   - Carga de datos iniciales para centros médicos
   - Generación de escala mensual de prueba

## 📊 Tablas Principales

### 🏥 Gestión de Centros

| Tabla | Descripción | Registros |
|-------|-------------|-----------|
| `ACS_CENTRO_MEDICO` | Hospitales y clínicas | 4 |
| `ACS_PUESTO_MEDICO` | Puestos de trabajo (Emergencias, Consulta, etc.) | 7 |
| `ACS_PUESTOXCENTRO` | Relación centros-puestos | 15 |

### 💊 Procedimientos Médicos

| Tabla | Descripción | Registros |
|-------|-------------|-----------|
| `ACS_PROCEDIMIENTO` | Catálogo de procedimientos | 15 |
| `ACS_PROCEDIMIENTOXCENTRO` | Precios por centro | 26 |
| `ACS_PROC_APLICADO` | Procedimientos realizados | Variable |
| `ACS_HISTORIAL_PROCEDIMIENTO` | Auditoría de precios | Variable |

### 👨‍⚕️ Médicos y Turnos

| Tabla | Descripción | Registros |
|-------|-------------|-----------|
| `ACS_MEDICO` | Información de médicos | 2 |
| `ACS_TURNO` | Turnos base (plantilla) | 5 |
| `ACS_ESCALA_MENSUAL` | Calendario mensual por centro | 1 (Nov 2025) |
| `ACS_DETALLE_MENSUAL` | Turnos diarios específicos | ~150 (30 días × 5 turnos) |
| `ACS_AUDITORIA_DETALLE_MENSUAL` | Auditoría de cambios | Variable |

## 🔑 Datos de Prueba Cargados

### Centros Médicos

```
1. Hospital Central (San José) - Completo
2. Clínica Santa Rita (Heredia) - Mediano
3. Centro Médico del Valle (Cartago) - Pequeño
4. Clínica Los Robles (Alajuela) - Pequeño
```

### Médicos Registrados

```
- Juan Camacho (118690700) - Medicina General
- Carlos Ramírez (CED345678) - Medicina de Emergencias
```

### Puestos Médicos

```
- Emergencias (24/7)
- Consulta Externa
- Hospitalización
- Cirugía
- Cuidados Intensivos
- Pediatría
- Ginecología
```

### Procedimientos Comunes

```
- Consulta General: ₡25,000 (costo) / ₡15,000 (pago médico)
- Consulta Especializada: ₡50,000 / ₡30,000
- Electrocardiograma: ₡35,000 / ₡20,000
- Radiografía: ₡40,000 / ₡22,000
- Ultrasonido: ₡60,000 / ₡35,000
- Cirugía Menor: ₡150,000 / ₡80,000
- Parto Normal: ₡500,000 / ₡250,000
- Cesárea: ₡800,000 / ₡400,000
```

## 🚀 Procedimientos Disponibles

### Gestión de Escalas

#### 1. Generar Escala Mensual

```sql
EXEC PRC_GENERAR_ESCALA_MENSUAL(
    p_acm_id => 1,      -- ID del centro
    p_mes    => 11,     -- Mes (1-12)
    p_anio   => 2025    -- Año
);
```

**Resultado**: Crea automáticamente todos los turnos del mes según plantilla base.

#### 2. Consultar Escalas

```sql
EXEC PRC_Consultar_Escalas(
    p_acm_id => 1,
    p_mes    => 11,
    p_anio   => 2025
);
```

**Resultado**: Muestra el calendario completo con turnos asignados.

#### 3. Asignar Médico a Turno

```sql
EXEC PRC_Asignar_Medico_Turno(
    p_adm_id => 123,    -- ID del detalle mensual
    p_ame_id => 1       -- ID del médico
);
```

**Resultado**: Reasigna médico y marca turno como 'REEMPLAZADO'.

#### 4. Cambiar Estado de Escala

```sql
EXEC PRC_Escala_Cambiar_Estado(
    p_aem_id => 1,
    p_estado => 'VIGENTE'  -- CONSTRUCCION | VIGENTE | EN REVISION | LISTA PARA PAGO | PROCESADA
);
```

#### 5. Marcar Escalas para Pago

```sql
-- Marcar todas las escalas del mes
EXEC PRC_Escalas_Marcar_Lista_Pago(
    p_mes    => 11,
    p_anio   => 2025,
    p_acm_id => NULL    -- NULL = todos los centros
);

-- Marcar solo un centro específico
EXEC PRC_Escalas_Marcar_Lista_Pago(11, 2025, 1);
```

#### 6. Procesar Escalas del Mes

```sql
EXEC PRC_Escalas_Procesar_Por_Mes(
    p_mes  => 11,
    p_anio => 2025
);
```

**Resultado**: Cambia todas las escalas de 'LISTA PARA PAGO' a 'PROCESADA'.

## 🔄 Flujo de Estados de Escala

```
CONSTRUCCION → VIGENTE → EN REVISION → LISTA PARA PAGO → PROCESADA
    ↓              ↓            ↓               ↓              ↓
[Generación]  [Activa]    [Revisión]    [Completa]    [Pagada]
```

## 🎯 Triggers Automáticos

### 1. `TRG_AUDIT_DETALLE_MENSUAL`

- **Dispara**: Después de INSERT/UPDATE/DELETE en `ACS_DETALLE_MENSUAL`
- **Acción**: Registra cambios en `ACS_AUDITORIA_DETALLE_MENSUAL`
- **Información**: Usuario, acción, campos modificados

### 2. `TRG_UPDATE_ESTADO_ESCALA`

- **Dispara**: Después de UPDATE de `ADM_ESTADO_TURNO`
- **Acción**: Automáticamente marca escala como 'LISTA PARA PAGO'
- **Condición**: Todos los turnos deben estar CUMPLIDO o REEMPLAZADO

### 3. `TRG_PROC_APLICADO_VALID`

- **Dispara**: Antes de INSERT/UPDATE en `ACS_PROC_APLICADO`
- **Acción**: Completa automáticamente `APA_COSTO` y `APA_PAGO` desde procedimiento
- **Validación**: No permite valores nulos o negativos

### 4. `TRG_HIST_PROCEDIMIENTO`

- **Dispara**: Después de UPDATE en `ACS_PROCEDIMIENTO`
- **Acción**: Guarda historial de precios
- **Función**: Auditoría de cambios de costos y pagos

## 📈 Consultas Útiles

### Ver Turnos de un Médico

```sql
SELECT 
    DM.ADM_FECHA,
    T.ATU_NOMBRE,
    T.ATU_HORA_INICIO,
    T.ATU_HORA_FIN,
    DM.ADM_ESTADO_TURNO,
    CM.ACM_NOMBRE AS CENTRO
FROM ACS_DETALLE_MENSUAL DM
INNER JOIN ACS_TURNO T ON DM.ATU_ID = T.ATU_ID
INNER JOIN ACS_ESCALA_MENSUAL EM ON DM.AEM_ID = EM.AEM_ID
INNER JOIN ACS_CENTRO_MEDICO CM ON EM.ACM_ID = CM.ACM_ID
WHERE DM.AME_ID = 1  -- ID del médico
AND EXTRACT(MONTH FROM DM.ADM_FECHA) = 11
AND EXTRACT(YEAR FROM DM.ADM_FECHA) = 2025
ORDER BY DM.ADM_FECHA, T.ATU_HORA_INICIO;
```

### Resumen de Procedimientos por Centro

```sql
SELECT 
    CM.ACM_NOMBRE,
    P.APD_NOMBRE,
    PC.APRC_COSTO,
    PC.APRC_PAGO,
    PC.APRC_COSTO - PC.APRC_PAGO AS UTILIDAD
FROM ACS_PROCEDIMIENTOXCENTRO PC
INNER JOIN ACS_CENTRO_MEDICO CM ON PC.ACM_ID = CM.ACM_ID
INNER JOIN ACS_PROCEDIMIENTO P ON PC.APD_ID = P.APD_ID
WHERE PC.APRC_ESTADO = 'ACTIVO'
ORDER BY CM.ACM_NOMBRE, P.APD_NOMBRE;
```

### Estado de Escalas Mensuales

```sql
SELECT 
    CM.ACM_NOMBRE,
    EM.AEM_MES || '/' || EM.AEM_ANIO AS PERIODO,
    EM.AEM_ESTADO,
    COUNT(DM.ADM_ID) AS TOTAL_TURNOS,
    SUM(CASE WHEN DM.ADM_ESTADO_TURNO = 'CUMPLIDO' THEN 1 ELSE 0 END) AS CUMPLIDOS,
    SUM(CASE WHEN DM.ADM_ESTADO_TURNO = 'FALTA' THEN 1 ELSE 0 END) AS FALTAS,
    SUM(CASE WHEN DM.ADM_ESTADO_TURNO = 'REEMPLAZADO' THEN 1 ELSE 0 END) AS REEMPLAZADOS
FROM ACS_ESCALA_MENSUAL EM
INNER JOIN ACS_CENTRO_MEDICO CM ON EM.ACM_ID = CM.ACM_ID
LEFT JOIN ACS_DETALLE_MENSUAL DM ON EM.AEM_ID = DM.AEM_ID
GROUP BY CM.ACM_NOMBRE, EM.AEM_MES, EM.AEM_ANIO, EM.AEM_ESTADO
ORDER BY EM.AEM_ANIO DESC, EM.AEM_MES DESC;
```

### Auditoría de Cambios en Turnos

```sql
SELECT 
    AUM_FECHA,
    AUM_USUARIO,
    AUM_ACCION,
    AUM_CAMBIOS,
    AUM_ESTADO_TURNO,
    ADM_ID
FROM ACS_AUDITORIA_DETALLE_MENSUAL
WHERE TRUNC(AUM_FECHA) = TRUNC(SYSDATE)
ORDER BY AUM_FECHA DESC;
```

## ⚠️ Notas Importantes

### Relación Médicos-Usuarios

```sql
-- ACS_MEDICO.AME_ID = ACS_USUARIO.AUS_ID
-- Un usuario con tipo 'MEDICO' aprobado automáticamente tiene registro en ACS_MEDICO
```

### Estados de Turno

- **CUMPLIDO**: Turno completado correctamente
- **FALTA**: Médico no asistió
- **CANCELADO**: Turno cancelado (no se puede reasignar)
- **REEMPLAZADO**: Médico fue cambiado

### Tipos de Pago de Turno

- **TURNO**: Pago fijo por turno completo (usar `ATU_PAGO`)
- **HORAS**: Pago por hora trabajada (usar `ATU_TARIFA_HORARIA`)

### Campos Calculados

```sql
-- Horas de un turno
EXTRACT(HOUR FROM (ATU_HORA_FIN - ATU_HORA_INICIO))

-- Tarifa horaria (si tipo pago = HORAS)
ATU_PAGO / EXTRACT(HOUR FROM (ATU_HORA_FIN - ATU_HORA_INICIO))
```

## 🔧 Correcciones Aplicadas

### Problemas Corregidos

1. ✅ Nombres de constraints con sintaxis inválida
2. ✅ Índices con nombres duplicados
3. ✅ Tabla `ACS_MEDICO` no existía (creada)
4. ✅ Tabla `ACS_DETALLE_MENSUAL` no existía (creada)
5. ✅ Tabla `ACS_HISTORIAL_PROCEDIMIENTO` no existía (creada)
6. ✅ Campos `APD_COSTO` y `APD_PAGO` faltantes en `ACS_PROCEDIMIENTO`
7. ✅ Campo `ATU_TARIFA_HORARIA` faltante en `ACS_TURNO`

## 🧪 Datos de Prueba Incluidos

- ✅ 4 centros médicos
- ✅ 7 puestos médicos
- ✅ 15 relaciones puesto×centro
- ✅ 15 procedimientos médicos
- ✅ 26 relaciones procedimiento×centro
- ✅ 2 médicos activos
- ✅ 5 turnos base (plantilla)
- ✅ 1 escala mensual (Noviembre 2025, Hospital Central)
- ✅ ~150 detalles mensuales generados
- ✅ 20 turnos asignados a médicos
- ✅ 2 procedimientos aplicados de ejemplo

## 📞 Integración con Otros Módulos

### Módulo de Personal (`4.2-datos_personal.sql`)

- **Requiere**: Usuarios aprobados con tipo 'MEDICO'
- **Genera**: Registros en `ACS_MEDICO` automáticamente

### Módulo de Planillas

- **Consume**: Escalas en estado 'LISTA PARA PAGO'
- **Lee**: `ACS_DETALLE_MENSUAL` para calcular pagos
- **Usa**: `ACS_PROC_APLICADO` para procedimientos extras

### Módulo de Correos

- **Notifica**: Cambios de estado en escalas
- **Alerta**: Turnos sin asignar médico
- **Confirma**: Escalas marcadas para pago

## 🎓 Ejemplo de Uso Completo

```sql
-- 1. Generar escala para diciembre 2025
EXEC PRC_GENERAR_ESCALA_MENSUAL(1, 12, 2025);

-- 2. Asignar médicos a turnos específicos
EXEC PRC_Asignar_Medico_Turno(201, 1);  -- Turno 201 → Médico 1
EXEC PRC_Asignar_Medico_Turno(202, 2);  -- Turno 202 → Médico 2

-- 3. Cambiar estado a vigente
EXEC PRC_Escala_Cambiar_Estado(2, 'VIGENTE');

-- 4. Consultar calendario
EXEC PRC_Consultar_Escalas(1, 12, 2025);

-- 5. Al finalizar el mes, marcar para pago
EXEC PRC_Escalas_Marcar_Lista_Pago(12, 2025, 1);

-- 6. Generar planillas (módulo planillas)
-- ...

-- 7. Marcar como procesada
EXEC PRC_Escalas_Procesar_Por_Mes(12, 2025);
```

## 📝 Log de Cambios

### v1.0 - 10/11/2025

- ✅ Creación inicial del módulo
- ✅ Tablas faltantes agregadas
- ✅ Correcciones de schema aplicadas
- ✅ Datos de prueba cargados
- ✅ Procedimientos y triggers validados
- ✅ Documentación completa

---

**Autor**: Sistema ACS  
**Fecha**: Noviembre 10, 2025  
**Versión**: 1.0
