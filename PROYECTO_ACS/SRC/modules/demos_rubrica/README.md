# 🎯 DEMOS DE RÚBRICA - PROYECTO ACS

## 📋 Descripción

Este directorio contiene scripts de demostración organizados por cada punto de la rúbrica del proyecto. Cada script está diseñado para ser ejecutado **de forma independiente** en **PL/SQL Developer** o **SQL\*Plus**, permitiendo demostrar funcionalidades específicas al profesor.

---

## 📊 Estructura de Puntos de Rúbrica (82% Total)

### ✅ Scripts Disponiblejs

| #      | Script                                 | Punto Rúbrica     | %   | Estado       | Descripción                                                      |
| ------ | -------------------------------------- | ----------------- | --- | ------------ | ---------------------------------------------------------------- |
| **00** | `00_DATOS_PRUEBA_MAESTRO.sql`          | Datos Iniciales   | -   | ✅ Listo     | Carga de datos maestros (20 padrón TSE, usuarios, centros, etc.) |
| **01** | `01_ESCALAS_8_PORCIENTO.sql`           | Escalas Mensuales | 8%  | ✅ Listo     | Generar escala mensual desde base                                |
| **02** | `02_PLANILLAS_12_PORCIENTO.sql`        | Planillas         | 12% | ✅ Listo     | Planillas admin y médicas con deducciones                        |
| **03** | `03_COMPROBANTES_12_PORCIENTO.sql`     | Comprobantes      | 12% | ✅ Listo     | HTML + notificaciones email                                      |
| **04** | `04_MARCAR_PROCESADO_4_PORCIENTO.sql`  | Marcar Procesado  | 4%  | 🚧 Pendiente | Auto-marcar turnos/escalas/procedimientos                        |
| **05** | `05_MARCAR_NOTIFICADO_3_PORCIENTO.sql` | Marcar Notificado | 3%  | 🚧 Pendiente | Actualizar flag notificado tras email                            |
| **06** | `06_PADRON_NACIONAL_5_PORCIENTO.sql`   | Padrón TSE        | 5%  | ✅ Listo     | Carga 20 registros CSV TSE                                       |
| **07** | `07_BITACORAS_4_PORCIENTO.sql`         | Bitácoras         | 4%  | 🚧 Pendiente | Auditoría de planillas y escalas                                 |
| **08** | `08_ENCRIPTACION_5_PORCIENTO.sql`      | Encriptación      | 5%  | 🚧 Pendiente | Encrypt/decrypt procedimientos                                   |
| **09** | `09_SEGURIDAD_BD_9_PORCIENTO.sql`      | Seguridad BD      | 9%  | ✅ Listo     | Roles (3%) + Usuarios (3%) + Perfiles (3%)                       |
| **10** | `10_NOTIFICACIONES_20_PORCIENTO.sql`   | Notificaciones    | 20% | 🚧 Pendiente | 4 procesos (inactivos, tablespace, objetos, índices)             |

**Total Implementado:** 51% (Escalas 8% + Planillas 12% + Comprobantes 12% + Padrón 5% + Seguridad 9% + Financiero ~5%)

---

## 🚀 Instrucciones de Uso

### Opción 1: Ejecución en PL/SQL Developer (RECOMENDADO)

1. **Abrir PL/SQL Developer**

2. **Conectar con el usuario del esquema**

   - Usar las credenciales proporcionadas por el administrador del sistema
   - Asegurarse de conectar al PDB correcto (orclpdb)

3. **Cargar Datos Maestros (OBLIGATORIO PRIMERO)**

   ```sql
   -- Ejecutar en ventana SQL Window:
   @<RUTA_PROYECTO>\SRC\modules\demos_rubrica\00_DATOS_PRUEBA_MAESTRO.sql
   ```

   ⚠️ **Importante:** Este script debe ejecutarse UNA SOLA VEZ antes de cualquier demo.

4. **Ejecutar Scripts Individuales**

   Cada script puede abrirse en una **ventana nueva** de SQL Window para ejecutarse de forma independiente:

   - **Ventana 1:** Escalas - `01_ESCALAS_8_PORCIENTO.sql`
   - **Ventana 2:** Planillas - `02_PLANILLAS_12_PORCIENTO.sql`
   - **Ventana 3:** Comprobantes - `03_COMPROBANTES_12_PORCIENTO.sql`
   - **Ventana 4:** Padrón Nacional - `06_PADRON_NACIONAL_5_PORCIENTO.sql`
   - **Ventana 5:** Seguridad BD - `09_SEGURIDAD_BD_9_PORCIENTO.sql`

5. **Ejecutar con F8 o Botón Execute**

   Cada script mostrará mensajes explicativos de lo que está realizando.

### Opción 2: Ejecución en SQL\*Plus

```powershell
# Navegar al directorio de demos
cd <RUTA_PROYECTO>\PROYECTO_ACS\SRC\modules\demos_rubrica

# Conectar y ejecutar script (reemplazar credenciales)
sqlplus <usuario>/<password>@<host>:<puerto>/<servicio> @01_ESCALAS_8_PORCIENTO.sql

# Ejemplo (ajustar según su configuración):
sqlplus usuario/password@localhost:1521/orclpdb @01_ESCALAS_8_PORCIENTO.sql
```

### Opción 3: Ejecución Completa Automatizada

```powershell
# Ejecutar todos los demos en secuencia
sqlplus <usuario>/<password>@<host>:<puerto>/<servicio> @EJECUTAR_TODOS.sql
```

⚠️ **Nota de Seguridad:** Nunca compartan credenciales en documentación o repositorios públicos.

---

## 📁 Archivos de Soporte

### CSV y Datos Externos

| Archivo                            | Descripción                      | Ubicación        |
| ---------------------------------- | -------------------------------- | ---------------- |
| `padron_nacional_20_registros.csv` | 20 registros TSE formato oficial | `demos_rubrica/` |

### Scripts de Configuración

| Archivo                       | Propósito                                                                  |
| ----------------------------- | -------------------------------------------------------------------------- |
| `00_DATOS_PRUEBA_MAESTRO.sql` | Carga inicial de datos (padrón, usuarios, centros, turnos, procedimientos) |

---

## 🎬 Secuencia Recomendada para Defensa

### FASE 1: Preparación

1. ✅ Ejecutar `00_DATOS_PRUEBA_MAESTRO.sql`
2. ✅ Verificar carga exitosa con queries de validación

### FASE 2: Demostración de Funcionalidades

#### Demo 1: Escalas Mensuales (8%)

```sql
-- Ejecutar: 01_ESCALAS_8_PORCIENTO.sql
```

**Funcionalidades Demostradas:**

- Crear escala base (plantilla semanal Lun-Vie)
- Generar escala mensual automática desde la base
- Asignar médicos a turnos específicos
- Cambiar estados: CONSTRUCCION → VIGENTE → LISTA_PAGO

---

#### Demo 2: Planillas Administrativas y Médicas (12%)

```sql
-- Ejecutar: 02_PLANILLAS_12_PORCIENTO.sql
```

**Funcionalidades Demostradas:**

- Planilla administrativa con deducciones automáticas (CCSS, Renta, etc.)
- Planilla médica con cálculo de turnos + procedimientos
- Cálculo automático de salarios brutos y netos
- Integración con módulo financiero (generación de asientos contables)

---

#### Demo 3: Comprobantes y Notificaciones (12%)

```sql
-- Ejecutar: 03_COMPROBANTES_12_PORCIENTO.sql
```

**Funcionalidades Demostradas:**

- Generación de comprobantes HTML profesionales
- Sistema de notificaciones por email (simulado)
- Rastreo de envíos con flag de notificado
- Función `FNC_GENERAR_COMPROBANTE_HTML()`
- Procedimiento `PRC_ENVIAR_COMPROBANTES_PLANILLA()`

---

#### Demo 4: Padrón Nacional TSE (5%)

```sql
-- Ejecutar: 06_PADRON_NACIONAL_5_PORCIENTO.sql
```

**Funcionalidades Demostradas:**

- Carga de 20 registros en formato CSV del TSE
- Función de verificación de cédulas: `FNC_VERIFICAR_CEDULA_TSE()`
- Integración con personal del sistema
- Estadísticas demográficas (distribución por sexo y edad)

---

#### Demo 5: Seguridad de Base de Datos (9%)

```sql
-- Ejecutar: 09_SEGURIDAD_BD_9_PORCIENTO.sql
```

**Funcionalidades Demostradas:**

**Perfiles (3%):**

- ADMIN_ACS: Administradores con límites amplios
- USUARIO_ACS: Usuarios estándar con restricciones moderadas
- CONSULTA_ACS: Solo lectura con límites estrictos

**Roles (3%):**

- ROL_ADMIN_ACS: Acceso completo al sistema
- ROL_RRHH_ACS: Gestión de planillas y personal
- ROL_MEDICO_ACS: Consultas propias y registro de procedimientos
- ROL_CONSULTA_ACS: Solo lectura en todas las tablas

**Usuarios (3%):**

- Usuarios de BD creados con roles y perfiles asignados
- Demostración de separación de privilegios

---

### FASE 3: Validaciones y Preguntas

- Ejecutar queries de validación
- Mostrar integridad referencial
- Demostrar triggers automáticos funcionando
- Mostrar reportes financieros generados

---

## 🔍 Validaciones Rápidas

### Verificar que todo funciona:

```sql
-- 1. Ver escalas generadas
SELECT COUNT(*) FROM ACS_ESCALA_MENSUAL;

-- 2. Ver planillas procesadas
SELECT APL_TIPO, APL_MES, APL_ANIO, APL_ESTADO, APL_SALARIO_NETO
FROM ACS_PLANILLA
ORDER BY APL_FECHA_CREACION DESC;

-- 3. Ver asientos financieros
SELECT AAF_TIPO, AAF_CONCEPTO, AAF_MONTO
FROM ACS_ASIENTO_FINANCIERO
ORDER BY AAF_FECHA_REGISTRO DESC;

-- 4. Ver padrón cargado
SELECT COUNT(*) FROM ACS_PADRON_NACIONAL;

-- 5. Ver usuarios de seguridad
SELECT USERNAME, PROFILE, ACCOUNT_STATUS
FROM DBA_USERS
WHERE USERNAME LIKE '%_ACS';
```

---

## ⚠️ Notas Importantes

### Requisitos Previos

- ✅ Oracle 19c corriendo en Docker o instalación local
- ✅ Conexión al usuario propietario del esquema ACS
- ✅ Tablas ACS creadas (ejecutar `acs_script_completo.sql` si es necesario)
- ✅ Tablespaces creados (ejecutar `crear_acs_tablespaces.sql` si es necesario)
- ✅ Triggers del módulo financiero compilados

### Dependencias entre Scripts

- **00_DATOS_MAESTRO** debe ejecutarse PRIMERO (una sola vez)
- **01_ESCALAS** debe ejecutarse antes de **02_PLANILLAS_MEDICAS**
- **02_PLANILLAS** debe ejecutarse antes de **03_COMPROBANTES**
- Los demás scripts (06 y 09) son independientes

### Errores Comunes y Soluciones

| Error                                      | Causa                                     | Solución                                           |
| ------------------------------------------ | ----------------------------------------- | -------------------------------------------------- |
| `ORA-00942: table or view does not exist`  | No se ejecutó el script de datos maestros | Ejecutar `00_DATOS_MAESTRO` primero                |
| `ORA-01031: insufficient privileges`       | Usuario sin permisos necesarios           | Verificar conexión con usuario del esquema         |
| `ORA-01403: no data found`                 | Falta ejecutar scripts previos en orden   | Revisar dependencias y ejecutar scripts anteriores |
| `ORA-02291: integrity constraint violated` | Faltan datos en tablas padre              | Ejecutar `00_DATOS_MAESTRO` completamente          |

### Verificación de Ambiente

Antes de ejecutar los demos, verificar el ambiente con estos comandos:

```sql
-- 1. Verificar conexión y usuario actual
SELECT USER, SYSTIMESTAMP FROM DUAL;

-- 2. Ver tablas disponibles
SELECT COUNT(*) AS "Total Tablas ACS"
FROM USER_TABLES
WHERE TABLE_NAME LIKE 'ACS_%';
-- Esperado: ~40 tablas

-- 3. Verificar tablespaces
SELECT TABLESPACE_NAME
FROM USER_TABLESPACES
WHERE TABLESPACE_NAME LIKE '%ACS%';
-- Esperado: TBS_ACS_DATOS, TBS_ACS_INDICES

-- 4. Ver estado de triggers
SELECT TRIGGER_NAME, STATUS
FROM USER_TRIGGERS
WHERE TRIGGER_NAME LIKE 'TRG_%'
ORDER BY TRIGGER_NAME;
-- Verificar que estén ENABLED

-- 5. Verificar procedimientos compilados
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_TYPE IN ('PROCEDURE', 'FUNCTION')
AND OBJECT_NAME LIKE 'PRC_%' OR OBJECT_NAME LIKE 'FNC_%'
ORDER BY OBJECT_NAME;
-- Verificar que estén VALID
```

---

## 📊 Resumen de Cobertura

| Módulo         | Implementado | Documentado | Probado |
| -------------- | ------------ | ----------- | ------- |
| Escalas        | ✅ 100%      | ✅ Completo | ✅ Sí   |
| Planillas      | ✅ 100%      | ✅ Completo | ✅ Sí   |
| Comprobantes   | ✅ 100%      | ✅ Completo | ✅ Sí   |
| Financiero     | ✅ 100%      | ✅ Completo | ✅ Sí   |
| Padrón TSE     | ✅ 100%      | ✅ Completo | ✅ Sí   |
| Seguridad BD   | ✅ 100%      | ✅ Completo | ✅ Sí   |
| Bitácoras      | 🚧 50%       | ⏳ Parcial  | ⏳ No   |
| Encriptación   | 🚧 50%       | ⏳ Parcial  | ⏳ No   |
| Notificaciones | 🚧 30%       | ⏳ Parcial  | ⏳ No   |

**Total Rubrica Cubierta:** ~51% completamente probado y funcional

---

## 🎓 Preparación para Defensa

### Checklist Pre-Defensa

- [ ] Verificar que Oracle 19c esté corriendo
- [ ] Confirmar conexión al esquema con las credenciales correctas
- [ ] Ejecutar `00_DATOS_MAESTRO` exitosamente (verificar sin errores)
- [ ] Probar cada script individual en el orden recomendado
- [ ] Verificar que todos los outputs sean correctos
- [ ] Preparar múltiples ventanas en PL/SQL Developer (una por demo)
- [ ] Tener queries de validación listas para ejecutar
- [ ] Revisar documentación de respaldo:
  - [ ] EXPLICACION_COMPLETA_ENUNCIADO.md
  - [ ] MODULO_FINANCIERO_COMPLETO.md
  - [ ] RESUMEN_EJECUTIVO_DEFENSA.md

### Preguntas Esperadas y Respuestas

| Pregunta                                       | Script a Ejecutar | Puntos Clave                                      |
| ---------------------------------------------- | ----------------- | ------------------------------------------------- |
| "¿Cómo generan las escalas mensuales?"         | `01_ESCALAS`      | Mostrar generación automática desde escala base   |
| "¿Cómo calculan las deducciones?"              | `02_PLANILLAS`    | Explicar tipos de movimiento y triggers           |
| "¿Cómo envían los comprobantes?"               | `03_COMPROBANTES` | Mostrar HTML generado y sistema de notificaciones |
| "¿Cómo verifican cédulas con TSE?"             | `06_PADRON`       | Demostrar función `FNC_VERIFICAR_CEDULA_TSE()`    |
| "¿Qué medidas de seguridad implementaron?"     | `09_SEGURIDAD`    | Explicar perfiles, roles y usuarios               |
| "¿Cómo registran los movimientos financieros?" | Queries ad-hoc    | Mostrar triggers automáticos y asientos           |

### Estructura de Presentación Sugerida

1. **Introducción (Contextualización)**

   - Explicar el propósito del sistema ACS
   - Mencionar cobertura de rúbrica (51% funcional)
   - Presentar arquitectura general

2. **Demostración Práctica (Core)**

   - Ejecutar demos en secuencia lógica
   - Explicar cada funcionalidad mientras se ejecuta
   - Destacar integraciones entre módulos
   - Resaltar módulo financiero como valor agregado

3. **Validaciones y Consultas**

   - Mostrar integridad de datos
   - Ejecutar queries de validación
   - Demostrar triggers funcionando en tiempo real

4. **Cierre y Preguntas**
   - Resumen de lo implementado
   - Apertura a preguntas del profesor
   - Tener documentación de respaldo lista

---

## 📞 Soporte y Troubleshooting

### Diagnóstico Rápido

Si encuentra errores durante la ejecución, seguir estos pasos:

#### 1. Verificar Conexión

```sql
SELECT USER, SYSTIMESTAMP FROM DUAL;
```

Confirmar que el usuario conectado es el propietario del esquema ACS.

#### 2. Ver Errores de Compilación

```sql
SELECT * FROM USER_ERRORS
WHERE NAME LIKE 'PRC_%' OR NAME LIKE 'FNC_%'
ORDER BY NAME, SEQUENCE;
```

#### 3. Recompilar Objetos Inválidos

```sql
BEGIN
    DBMS_UTILITY.COMPILE_SCHEMA(USER);
END;
/
```

#### 4. Verificar Estado de Triggers

```sql
SELECT TRIGGER_NAME, STATUS, TRIGGERING_EVENT
FROM USER_TRIGGERS
WHERE TRIGGER_NAME LIKE 'TRG_%'
ORDER BY TRIGGER_NAME;
```

#### 5. Habilitar Triggers (si están deshabilitados)

```sql
-- Triggers financieros
ALTER TRIGGER TRG_AF_PLANILLA_PROCESADA_AU ENABLE;
ALTER TRIGGER TRG_RESUMEN_FIN_MENSUAL_AI ENABLE;
ALTER TRIGGER TRG_RESUMEN_FIN_CENTRO_AI ENABLE;

-- Verificar
SELECT TRIGGER_NAME, STATUS FROM USER_TRIGGERS
WHERE TRIGGER_NAME LIKE '%FIN%';
```

### Problemas Comunes Específicos

#### Problema: Scripts no encuentran tablas

**Solución:**

1. Verificar que las tablas existan: `SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME LIKE 'ACS_%';`
2. Si no existen, ejecutar `acs_script_completo.sql` del directorio `SRC/database/`

#### Problema: Faltan datos maestros

**Solución:**
Ejecutar `00_DATOS_PRUEBA_MAESTRO.sql` y verificar con:

```sql
SELECT 'Padrón' AS Tabla, COUNT(*) AS Registros FROM ACS_PADRON_NACIONAL
UNION ALL SELECT 'Usuarios', COUNT(*) FROM ACS_USUARIO;
```

#### Problema: Triggers financieros no se disparan

**Solución:**

1. Verificar que existan: `SELECT COUNT(*) FROM USER_TRIGGERS WHERE TRIGGER_NAME LIKE '%FIN%';`
2. Si no existen, ejecutar: `SRC/modules/financiero/triggers/crear_trgs_financiero_v2.sql`

### Contacto y Recursos Adicionales

- **Documentación Completa:** Revisar `RESUMEN_EJECUTIVO_DEFENSA.md` en la raíz del proyecto
- **Documentación Técnica:** Consultar `MODULO_FINANCIERO_COMPLETO.md` para detalles del módulo financiero
- **Mapeo de Requisitos:** Ver `EXPLICACION_COMPLETA_ENUNCIADO.md` para entender la correspondencia con el enunciado

---

## 📝 Actualizado

**Última actualización:** 9 de noviembre de 2025  
**Scripts completados:** 5/10 (51% de rúbrica)  
**Estado:** ✅ Listo para defensa con puntos implementados
